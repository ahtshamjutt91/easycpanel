#!/bin/bash
# litespeed.sh — Install, verify and optimize LiteSpeed Web Server on cPanel
#
# Two-phase design:
#   Phase 1 (LSWS not yet installed): license guardrails, pre-flight checks
#     against server RAM / CPU / account count, WHM plugin installation and
#     guided LSWS installation with a safe port-offset trial.
#   Phase 2 (LSWS detected): license verification, firewall integration
#     (HTTP/3 UDP 443, WebAdmin lockdown), LSCache setup and hardening.
# Run the script again after completing the WHM installation step to apply
# Phase 2 automatically.
#
# Created by Ahtsham Jutt — https://www.ahtshamjutt.com

# ── Load the EasycPanel shared library ────────────────────────────────
# Colors, box drawing, logging, backups, detection and tuning helpers
# live in lib.sh. If this script was downloaded standalone, lib.sh is
# fetched from the project mirror first.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ ! -f "$SCRIPT_DIR/lib.sh" ]; then
    wget -q -O "$SCRIPT_DIR/lib.sh" "https://script.ahtshamjutt.com/easycpanel/lib.sh" || rm -f "$SCRIPT_DIR/lib.sh"
fi
if [ ! -f "$SCRIPT_DIR/lib.sh" ]; then
    echo "FATAL: lib.sh is missing and could not be downloaded from the project mirror."
    exit 1
fi
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

# Initialize optimization flag (used to control screen clearing)
OPTIMIZATION_STARTED="no"

# Define the log file location
LOG_FILE="/root/panelbot-litespeed.log"

# Create backup directory structure
BACKUP_DIR="/backup/panelbot-litespeed-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Check for Root Privileges
require_root

LSWS_DIR="/usr/local/lsws"
SERIAL_FILE="/root/.litespeed_serial"

# Clear the screen for a clean look
clear

# Display a compact banner
btop "$BLUE"
bctr "$BLUE" "${GREEN}LiteSpeed Web Server for cPanel — Install & Optimize"
bctr "$BLUE" "${YELLOW}Created by Ahtsham Jutt"
bctr "$BLUE" "${WHITE}Website: ahtshamjutt.com | me@ahtshamjutt.com"
bctr "$BLUE" "${CYAN}Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕"
bbot "$BLUE"
sleep 1

# Basic environment checks
section_header "Checking Environment"
detect_os

if [ ! -d /usr/local/cpanel ]; then
    error_msg "cPanel is not installed on this server. Install cPanel first."
    exit 1
fi
success_msg "cPanel installation detected"

check_cpanel_license

# Gather server facts used by the pre-flight checks
RAM_GB=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
[ "$RAM_GB" -lt 1 ] && RAM_GB=1
CPU_CORES=$(nproc)
ACCOUNTS=$(find /var/cpanel/users -maxdepth 1 -type f 2>/dev/null | wc -l)
DOMAINS=$(grep -vc "^\*" /etc/userdomains 2>/dev/null || echo 0)

echo; btop "$CYAN"
bctr "$CYAN" "${WHITE}Server Facts"
bsep "$CYAN"
brow "$CYAN" "${WHITE} RAM: ${GREEN}${RAM_GB} GB${WHITE}   CPU cores: ${GREEN}${CPU_CORES}"
brow "$CYAN" "${WHITE} cPanel accounts: ${GREEN}${ACCOUNTS}${WHITE}   Domains: ${GREEN}${DOMAINS}"
bbot "$CYAN"

# ══════════════════════════════════════════════════════════════════════
# PHASE 2 — LiteSpeed already installed: verify, integrate and optimize
# ══════════════════════════════════════════════════════════════════════
if [ -x "$LSWS_DIR/bin/lshttpd" ]; then
    section_header "LiteSpeed Detected — Verifying and Optimizing"

    # License verification
    process_step "Verifying LiteSpeed license"
    LSWS_VERSION_INFO=$("$LSWS_DIR/bin/lshttpd" -V 2>&1)
    log "$LSWS_VERSION_INFO"
    if echo "$LSWS_VERSION_INFO" | grep -qi "expire\|invalid\|error"; then
        warning_msg "License problem reported — review: $LSWS_DIR/bin/lshttpd -V"
    else
        success_msg "LiteSpeed license verified"
    fi

    # Backup LSWS configuration before any changes
    backup_file "$LSWS_DIR/conf/httpd_config.xml" "litespeed"

    # WebAdmin console: strong random password, saved root-only
    section_header "Hardening LiteSpeed WebAdmin"
    if [ -x "$LSWS_DIR/admin/misc/admpass.sh" ]; then
        process_step "Setting a strong WebAdmin password"
        LSWS_ADMIN_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
        if printf 'admin\n%s\n%s\n' "$LSWS_ADMIN_PASS" "$LSWS_ADMIN_PASS" | "$LSWS_DIR/admin/misc/admpass.sh" >/dev/null 2>&1; then
            echo "$LSWS_ADMIN_PASS" > /root/.lsws_webadmin.pass
            chmod 600 /root/.lsws_webadmin.pass
            success_msg "WebAdmin password set (saved to /root/.lsws_webadmin.pass)"
        else
            warning_msg "Could not set WebAdmin password automatically"
        fi
    fi

    # Firewall integration (CSF)
    if [ -f /etc/csf/csf.conf ]; then
        section_header "Firewall Integration (CSF)"
        backup_file "/etc/csf/csf.conf" "litespeed"

        # HTTP/3 (QUIC) needs UDP 443 open or it silently never activates
        process_step "Ensuring UDP 443 is open for HTTP/3 (QUIC)"
        if ! grep -E '^UDP_IN' /etc/csf/csf.conf | grep -qw 443; then
            sed -i '/^UDP_IN/ s/"$/,443"/' /etc/csf/csf.conf
            success_msg "UDP 443 added to CSF UDP_IN (HTTP/3 enabled)"
        else
            success_msg "UDP 443 already open in CSF"
        fi

        # WebAdmin console port must not be publicly reachable
        process_step "Closing WebAdmin port 7080 to the public"
        if grep -E '^TCP_IN' /etc/csf/csf.conf | grep -qw 7080; then
            sed -i '/^TCP_IN/ s/,7080\b//; /^TCP_IN/ s/\b7080,//' /etc/csf/csf.conf
            success_msg "Port 7080 removed from CSF TCP_IN (use an SSH tunnel to reach WebAdmin)"
        else
            success_msg "Port 7080 already closed (use an SSH tunnel to reach WebAdmin)"
        fi

        csf -r >/dev/null 2>&1
        success_msg "CSF reloaded"
    fi

    # ModSecurity rules carry over from Apache automatically
    section_header "Web Application Firewall"
    if rpm -q ea-modsec2-rules-owasp-crs >/dev/null 2>&1; then
        success_msg "OWASP ModSecurity rules present — LiteSpeed reads them from the Apache configuration"
    else
        process_step "Installing ModSecurity OWASP ruleset"
        yes | yum install ea-modsec2-rules-owasp-crs -y >/dev/null 2>&1 \
            && success_msg "ModSecurity OWASP ruleset installed" \
            || warning_msg "Could not install the OWASP ruleset — install it from WHM later"
    fi

    # LSCache for WordPress
    section_header "LiteSpeed Cache (LSCache)"
    LSCMCTL="$LSWS_DIR/admin/misc/lscmctl"
    if [ -x "$LSCMCTL" ]; then
        process_step "Scanning for WordPress installations"
        "$LSCMCTL" scan >/dev/null 2>&1 && success_msg "WordPress scan completed"

        if [ "$ACCOUNTS" -le 1 ]; then
            process_step "Enabling LSCache for discovered WordPress sites"
            "$LSCMCTL" enable -m >/dev/null 2>&1 \
                && success_msg "LSCache enabled for all discovered WordPress installations" \
                || warning_msg "LSCache mass-enable did not complete — manage it from the WHM LiteSpeed plugin"
        else
            echo; btop "$YELLOW"
            bctr "$YELLOW" "${WHITE}Shared server detected ($ACCOUNTS accounts)"
            bsep "$YELLOW"
            brow "$YELLOW" "${WHITE} Mass-enabling LSCache installs a plugin into every"
            brow "$YELLOW" "${WHITE} customer WordPress site. Enable it for all sites now?"
            bbot "$YELLOW"
            echo -e "${YELLOW}Enable LSCache for ALL WordPress sites? (y/N):${NC}"
            read -rp "▶ " lscache_choice
            if [[ "$lscache_choice" =~ ^[Yy]$ ]]; then
                "$LSCMCTL" enable -m >/dev/null 2>&1 \
                    && success_msg "LSCache enabled for all discovered WordPress installations" \
                    || warning_msg "LSCache mass-enable did not complete — manage it from the WHM LiteSpeed plugin"
            else
                success_msg "Skipped mass-enable — customers can enable LSCache per site"
            fi
        fi
    else
        warning_msg "lscmctl not found — manage LSCache from WHM > Plugins > LiteSpeed"
    fi

    # Determine which web server currently answers on port 80
    section_header "Service Status"
    PORT80_OWNER=$(ss -tlnp 2>/dev/null | grep -w ":80" | grep -o 'litespeed\|lshttpd\|httpd\|apache' | head -1)
    case "$PORT80_OWNER" in
        litespeed|lshttpd) success_msg "LiteSpeed is serving port 80 — switchover complete" ;;
        httpd|apache)
            warning_msg "Apache is still serving port 80 (LiteSpeed runs on the port-offset)"
            echo; btop "$CYAN"
            bctr "$CYAN" "${WHITE}Final Switchover"
            bsep "$CYAN"
            brow "$CYAN" "${WHITE} 1. Test your sites on the offset port first"
            brow "$CYAN" "${WHITE} 2. In WHM > Plugins > LiteSpeed set Port Offset to 0"
            brow "$CYAN" "${WHITE} 3. Choose 'Switch to LiteSpeed' — Apache stops, LSWS"
            brow "$CYAN" "${WHITE}    takes over ports 80/443 with zero config changes"
            brow "$CYAN" "${WHITE} 4. Rollback anytime: 'Switch to Apache' in the plugin"
            bbot "$CYAN"
            ;;
        *) warning_msg "Could not determine which server owns port 80 — check WHM > Plugins > LiteSpeed" ;;
    esac

    # Recommended manual WebAdmin settings (not automated by design —
    # values depend on your traffic; set them in WebAdmin > Configuration)
    echo; btop "$CYAN"
    bctr "$CYAN" "${WHITE}Recommended WebAdmin Settings (Security tab)"
    bsep "$CYAN"
    brow "$CYAN" "${WHITE} Per-client throttling: Connection Soft Limit ${GREEN}35"
    brow "$CYAN" "${WHITE}                        Connection Hard Limit ${GREEN}60"
    brow "$CYAN" "${WHITE} Shared servers: enable reCAPTCHA protection under load"
    brow "$CYAN" "${WHITE} Keep 'Firewall Modifications' ${RED}OFF${WHITE} — CSF owns iptables"
    bbot "$CYAN"

    # Final summary
    echo; btop "$BLUE"
    bctr "$BLUE" "${GREEN}LITESPEED OPTIMIZATION COMPLETE"
    bsep "$BLUE"
    brow "$BLUE" " ${GREEN}• License:${NC} verified via lshttpd -V (details in $LOG_FILE)"
    brow "$BLUE" " ${GREEN}• WebAdmin:${NC} password in /root/.lsws_webadmin.pass (SSH tunnel to :7080)"
    brow "$BLUE" " ${GREEN}• HTTP/3:${NC} UDP 443 open in CSF"
    brow "$BLUE" " ${GREEN}• ModSecurity:${NC} OWASP rules active via Apache configuration"
    brow "$BLUE" " ${GREEN}• Backups:${NC} $BACKUP_DIR"
    bbot "$BLUE"
    log "LiteSpeed phase 2 completed"
    exit 0
fi

# ══════════════════════════════════════════════════════════════════════
# PHASE 1 — LiteSpeed not installed: guardrails and guided installation
# ══════════════════════════════════════════════════════════════════════
section_header "LiteSpeed License Selection"

echo; btop "$CYAN"
bctr "$CYAN" "${WHITE}LiteSpeed License Tiers"
bsep "$CYAN"
brow "$CYAN" "${WHITE} 1. Free Starter      — 1 domain,  2 GB RAM limit, free"
brow "$CYAN" "${WHITE} 2. Site Owner        — 5 domains, 8 GB RAM limit"
brow "$CYAN" "${WHITE} 3. Site Owner Plus   — 5 domains, no RAM limit"
brow "$CYAN" "${WHITE} 4. Web Host Lite     — unlimited domains, 8 GB RAM limit"
brow "$CYAN" "${WHITE} 5. Web Host Essential/Professional/Enterprise — no limits"
bsep "$CYAN"
brow "$CYAN" "${YELLOW} LiteSpeed will NOT run if server RAM exceeds the tier limit!"
bbot "$CYAN"

echo -e "\n${YELLOW}Which license tier will this server use? (1-5):${NC}"
while true; do
    read -rp "▶ " tier_choice
    [[ "$tier_choice" =~ ^[1-5]$ ]] && break
    echo -e "${RED}✗${NC} Please enter a number between 1 and 5."
done

# Pre-flight: compare the chosen tier against the server facts
PREFLIGHT_FAIL=false
case "$tier_choice" in
    1)
        TIER_NAME="Free Starter"
        [ "$RAM_GB" -gt 2 ] && PREFLIGHT_FAIL=true && RAM_LIMIT=2
        [ "$DOMAINS" -gt 1 ] && warning_msg "Free Starter covers 1 domain; this server has $DOMAINS"
        ;;
    2)
        TIER_NAME="Site Owner"
        [ "$RAM_GB" -gt 8 ] && PREFLIGHT_FAIL=true && RAM_LIMIT=8
        [ "$DOMAINS" -gt 5 ] && warning_msg "Site Owner covers 5 domains; this server has $DOMAINS"
        ;;
    3)
        TIER_NAME="Site Owner Plus"
        [ "$DOMAINS" -gt 5 ] && warning_msg "Site Owner Plus covers 5 domains; this server has $DOMAINS"
        ;;
    4)
        TIER_NAME="Web Host Lite"
        [ "$RAM_GB" -gt 8 ] && PREFLIGHT_FAIL=true && RAM_LIMIT=8
        ;;
    5)
        TIER_NAME="Web Host Essential or higher"
        ;;
esac
log "Chosen LiteSpeed tier: $TIER_NAME"

if [ "$PREFLIGHT_FAIL" = true ]; then
    echo; btop "$RED"
    bctr "$RED" "${WHITE}PRE-FLIGHT CHECK FAILED"
    bsep "$RED"
    brow "$RED" "${YELLOW} This server has ${WHITE}${RAM_GB} GB${YELLOW} RAM but the $TIER_NAME tier"
    brow "$RED" "${YELLOW} is limited to ${WHITE}${RAM_LIMIT} GB${YELLOW}. LiteSpeed will refuse to start."
    brow "$RED" "${YELLOW} Choose a higher tier or reduce server RAM."
    bbot "$RED"
    error_msg "Aborting LiteSpeed installation — license tier does not fit this server"
    exit 1
fi
success_msg "Pre-flight checks passed for the $TIER_NAME tier"

# Serial number (or trial)
echo -e "\n${WHITE}Do you have a license serial number?${NC}"
echo -e "${GREEN}1.${NC} Yes, I have a serial number"
echo -e "${GREEN}2.${NC} No, use a 15-day trial license"
read -rp "▶ " serial_choice

if [[ "$serial_choice" == "1" ]]; then
    echo -e "${YELLOW}Enter your LiteSpeed serial number:${NC}"
    while true; do
        read -rp "▶ " lsws_serial
        [ -n "$lsws_serial" ] && break
        echo -e "${RED}✗${NC} Serial number cannot be empty."
    done
    echo "$lsws_serial" > "$SERIAL_FILE"
    chmod 600 "$SERIAL_FILE"
    success_msg "Serial saved to $SERIAL_FILE (used during WHM installation)"
else
    echo "TRIAL" > "$SERIAL_FILE"
    chmod 600 "$SERIAL_FILE"
    success_msg "Trial mode selected — choose 'Trial' during the WHM installation"
fi

# Install the official WHM plugin
section_header "Installing the LiteSpeed WHM Plugin"
process_step "Downloading the official plugin installer from LiteSpeed"
cd /usr/src || exit 1
rm -f lsws_whm_plugin_install.sh
if ! wget -q https://litespeedtech.com/packages/cpanel/lsws_whm_plugin_install.sh; then
    error_msg "Could not download the LiteSpeed plugin installer — check connectivity"
    exit 1
fi
sh lsws_whm_plugin_install.sh >> "$LOG_FILE" 2>&1
rm -f lsws_whm_plugin_install.sh
if [ -d /usr/local/cpanel/whostmgr/docroot/cgi/lsws ]; then
    success_msg "LiteSpeed WHM plugin installed"
else
    error_msg "Plugin installation did not complete — see $LOG_FILE"
    exit 1
fi

# Guided next steps — the LSWS binary install runs from WHM so the
# license registration happens interactively and verifiably
echo; btop "$CYAN"
bctr "$CYAN" "${WHITE}NEXT STEPS — Complete the Installation in WHM"
bsep "$CYAN"
brow "$CYAN" "${WHITE} 1. Open WHM > Plugins > LiteSpeed Web Server"
brow "$CYAN" "${WHITE} 2. Click 'Install LiteSpeed Web Server'"
brow "$CYAN" "${WHITE}    • Serial: $( [ -s "$SERIAL_FILE" ] && grep -q TRIAL "$SERIAL_FILE" && echo "choose TRIAL" || echo "in $SERIAL_FILE" )"
brow "$CYAN" "${WHITE}    • Port Offset: ${GREEN}2000${WHITE} (test safely alongside Apache)"
brow "$CYAN" "${WHITE}    • PHP suEXEC: ${GREEN}Yes"
brow "$CYAN" "${WHITE} 3. Test a site on port 2080 once installed"
brow "$CYAN" "${WHITE} 4. Re-run this script: ${GREEN}bash litespeed.sh"
brow "$CYAN" "${WHITE}    It will verify the license, open UDP 443 for HTTP/3,"
brow "$CYAN" "${WHITE}    lock down WebAdmin, set up LSCache and guide switchover"
bbot "$CYAN"
log "LiteSpeed phase 1 completed — awaiting WHM installation"
