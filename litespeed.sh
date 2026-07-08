#!/bin/bash
# litespeed.sh — Install, verify and optimize LiteSpeed Web Server on cPanel
#
# Fully unattended installation using LiteSpeed's official autoinstaller,
# with license-tier guardrails, PHP handler compatibility conversion
# (PHP-FPM and mod_ruid2/mod_lsapi are NOT compatible with LiteSpeed),
# firewall integration, LSCache deployment and production hardening.
# Safe to re-run: on servers where LiteSpeed is already installed the
# script skips installation and applies verification and optimization.
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
# INSTALLATION (skipped when LiteSpeed is already present)
# ══════════════════════════════════════════════════════════════════════
if [ ! -x "$LSWS_DIR/bin/lshttpd" ]; then

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
    RAM_LIMIT=0
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
        echo -e "${YELLOW}Enter your LiteSpeed serial number (without any trailing bracket):${NC}"
        while true; do
            read -rp "▶ " LSWS_SERIAL
            LSWS_SERIAL=${LSWS_SERIAL%)}
            [ -n "$LSWS_SERIAL" ] && break
            echo -e "${RED}✗${NC} Serial number cannot be empty."
        done
    else
        LSWS_SERIAL="TRIAL"
        success_msg "Trial mode selected (15-day trial license)"
    fi

    # ── Compatibility conversion ──────────────────────────────────────
    # PHP-FPM and the mod_ruid2/mod_lsapi Apache modules are NOT
    # compatible with LiteSpeed. Convert every PHP version to suPHP and
    # disable PHP-FPM on all domains before installing.
    section_header "Preparing PHP Stack for LiteSpeed"

    process_step "Checking for incompatible Apache modules (ruid2/lsapi)"
    if httpd -M 2>/dev/null | grep -Eqi 'ruid2|lsapi'; then
        process_step "Removing mod_ruid2 / mod_lsapi"
        yum remove -y ea-apache24-mod_ruid2 ea-apache24-mod_lsapi >/dev/null 2>&1
        success_msg "Incompatible Apache modules removed"
    else
        success_msg "No incompatible Apache modules found"
    fi

    process_step "Ensuring suPHP is installed"
    if ! rpm -q ea-apache24-mod_suphp >/dev/null 2>&1; then
        yum install -y ea-apache24-mod_suphp >/dev/null 2>&1
    fi
    success_msg "suPHP available"

    process_step "Switching all PHP versions to the suPHP handler"
    for ver in $(whmapi1 php_get_installed_versions 2>/dev/null | awk '/ea-php/ {print $2}'); do
        whmapi1 php_set_handler version="$ver" handler=suphp >/dev/null 2>&1 \
            && log "Handler for $ver set to suphp" \
            || warning_msg "Could not switch $ver to suphp — check WHM > MultiPHP Manager"
    done
    success_msg "PHP handlers switched to suPHP"

    process_step "Disabling PHP-FPM on all domains (incompatible with LiteSpeed)"
    whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm=0 >/dev/null 2>&1
    awk -F': ' '$1 != "*" {print $1}' /etc/userdomains 2>/dev/null | while read -r dom; do
        [ -n "$dom" ] && whmapi1 php_set_vhost_versions vhost-0="$dom" php_fpm=0 >/dev/null 2>&1
    done
    /scripts/restartsrv_httpd >/dev/null 2>&1
    success_msg "PHP-FPM disabled (lsphp via LSAPI takes over under LiteSpeed)"

    log "Current PHP configuration: $(/usr/local/cpanel/bin/rebuild_phpconf --current 2>/dev/null | tr '\n' ' ')"

    # ── Unattended installation via the official autoinstaller ───────
    # Parameters: serial, PHP suEXEC=2 (user home directory only),
    # port offset 0 (replace Apache), admin user, admin password,
    # admin email, and the recommended enable flags.
    section_header "Installing LiteSpeed Web Server (unattended)"

    process_step "Downloading the official LiteSpeed autoinstaller"
    cd /usr/src || exit 1
    rm -f lsws_whm_autoinstaller.sh
    if ! wget -q https://www.litespeedtech.com/packages/cpanel/lsws_whm_autoinstaller.sh; then
        error_msg "Could not download the LiteSpeed autoinstaller — check connectivity"
        exit 1
    fi
    chmod a+x lsws_whm_autoinstaller.sh

    LSWS_ADMIN_PASS=$(tr -dc 'A-Za-z0-9_' < /dev/urandom | head -c 24)
    process_step "Running the autoinstaller (this takes several minutes)"
    if ./lsws_whm_autoinstaller.sh "$LSWS_SERIAL" 2 0 admin "$LSWS_ADMIN_PASS" root@localhost 1 1 1 >> "$LOG_FILE" 2>&1; then
        success_msg "LiteSpeed autoinstaller completed"
    else
        error_msg "Autoinstaller reported a problem — see $LOG_FILE"
    fi
    rm -f /usr/src/lsws_whm_autoinstaller.sh

    if [ ! -x "$LSWS_DIR/bin/lshttpd" ]; then
        error_msg "LiteSpeed was not installed — review $LOG_FILE and re-run this script"
        exit 1
    fi

    echo "$LSWS_ADMIN_PASS" > /root/.lsws_webadmin.pass
    chmod 600 /root/.lsws_webadmin.pass
    success_msg "WebAdmin password saved to /root/.lsws_webadmin.pass (user: admin)"

    if systemctl is-active --quiet lsws 2>/dev/null || systemctl is-active --quiet lshttpd 2>/dev/null; then
        success_msg "LiteSpeed service is running"
    else
        warning_msg "LiteSpeed service not reported active — check: systemctl status lsws"
    fi

    # TimeZoneDB for all lsphp versions
    process_step "Installing TimeZoneDB for all PHP versions"
    cd /usr/src || exit 1
    rm -f buildtimezone.sh
    if wget -q https://litespeedtech.com/packages/cpanel/buildtimezone.sh; then
        chmod a+x buildtimezone.sh
        ./buildtimezone.sh >> "$LOG_FILE" 2>&1 && success_msg "TimeZoneDB installed" \
            || warning_msg "TimeZoneDB build reported a problem — see $LOG_FILE"
        rm -f /usr/src/buildtimezone.sh
    else
        warning_msg "Could not download buildtimezone.sh — install TimeZoneDB from WHM later"
    fi
fi

# ══════════════════════════════════════════════════════════════════════
# VERIFICATION, FIREWALL INTEGRATION AND HARDENING
# ══════════════════════════════════════════════════════════════════════
section_header "Verifying LiteSpeed License"
LSWS_VERSION_INFO=$("$LSWS_DIR/bin/lshttpd" -V 2>&1)
log "$LSWS_VERSION_INFO"
if echo "$LSWS_VERSION_INFO" | grep -qi "expire in\|LiteSpeed"; then
    success_msg "LiteSpeed license verified (serial in $LSWS_DIR/conf/serial.no)"
else
    warning_msg "License problem reported — review: $LSWS_DIR/bin/lshttpd -V"
fi

# Backup LSWS configuration before any changes
backup_file "$LSWS_DIR/conf/httpd_config.xml" "litespeed"

# ── CSF firewall integration ──────────────────────────────────────────
if [ -f /etc/csf/csf.conf ]; then
    section_header "Firewall Integration (CSF)"
    backup_file "/etc/csf/csf.conf" "litespeed"

    # HTTP/3 (QUIC) needs UDP 443 open in AND out, or it silently never
    # activates (IPv6 lists included for servers that use IPv6)
    process_step "Opening UDP 443 for HTTP/3 (QUIC)"
    for key in UDP_IN UDP_OUT UDP6_IN UDP6_OUT; do
        if grep -qE "^$key = \"" /etc/csf/csf.conf && ! grep -E "^$key" /etc/csf/csf.conf | grep -qw 443; then
            sed -i "/^$key = / s/\"$/,443\"/" /etc/csf/csf.conf
            log "Added 443 to CSF $key"
        fi
    done
    success_msg "UDP 443 open in CSF (QUIC enabled; note: QUIC does not apply behind Cloudflare proxy)"

    # WebAdmin console port must not be publicly reachable
    process_step "Closing WebAdmin port 7080 to the public"
    if grep -E '^TCP_IN' /etc/csf/csf.conf | grep -qw 7080; then
        sed -i '/^TCP_IN/ s/,7080\b//; /^TCP_IN/ s/\b7080,//' /etc/csf/csf.conf
    fi
    success_msg "Port 7080 closed (reach WebAdmin via SSH tunnel or WHM plugin)"

    # LFD process ignore entries — without these, LFD emails constant
    # "suspicious process" alerts for every lsphp process
    process_step "Adding LiteSpeed binaries to the LFD ignore list"
    for line in \
        'pexe:^/usr/local/lsws/bin/lshttpd.*' \
        'pexe:^/opt/cpanel/ea-php\d\d/root/usr/bin/lsphp' \
        'pexe:^/opt/alt/php.*/usr/bin/lsphp' \
        'pexe:^/opt/cpanel/ea-php\d\d/root/usr/bin/lsphp\.cagefs'; do
        grep -qxF "$line" /etc/csf/csf.pignore 2>/dev/null || echo "$line" >> /etc/csf/csf.pignore
    done
    success_msg "LFD ignore entries added"

    csf -r >/dev/null 2>&1
    systemctl restart lfd >/dev/null 2>&1
    success_msg "CSF and LFD reloaded"
fi

# ── Imunify WAF vendor rules ──────────────────────────────────────────
if command -v imunify360-agent >/dev/null 2>&1; then
    section_header "Switching Imunify WAF Rules to LiteSpeed"
    process_step "Re-detecting web server for Imunify rulesets"
    imunify360-agent install-vendors >> "$LOG_FILE" 2>&1 \
        && success_msg "Imunify WAF rules switched to the LiteSpeed vendor set" \
        || warning_msg "imunify360-agent install-vendors reported a problem — see $LOG_FILE"
fi

# ── ModSecurity rules (LiteSpeed reads Apache's configuration) ───────
section_header "Web Application Firewall"
if rpm -q ea-modsec2-rules-owasp-crs >/dev/null 2>&1; then
    success_msg "OWASP ModSecurity rules present — LiteSpeed reads them from the Apache configuration"
else
    process_step "Installing ModSecurity OWASP ruleset"
    yes | yum install ea-modsec2-rules-owasp-crs -y >/dev/null 2>&1 \
        && success_msg "ModSecurity OWASP ruleset installed" \
        || warning_msg "Could not install the OWASP ruleset — install it from WHM later"
fi

# ── WordPress brute-force protection ─────────────────────────────────
# Built into LiteSpeed: throttle by default. Switch to drop after 10
# attempts to free connections for legitimate traffic.
section_header "WordPress Brute-Force Protection"
LSWS_CONF="$LSWS_DIR/conf/httpd_config.xml"
if grep -q "<wpProtectAction>" "$LSWS_CONF" 2>/dev/null; then
    sed -i 's|<wpProtectAction>[0-9]*</wpProtectAction>|<wpProtectAction>4</wpProtectAction>|' "$LSWS_CONF"
    sed -i 's|<wpProtectLimit>[0-9]*</wpProtectLimit>|<wpProtectLimit>10</wpProtectLimit>|' "$LSWS_CONF"
    success_msg "wp-login/xmlrpc protection set to drop after 10 attempts"
else
    warning_msg "wpProtect keys not present in the config — set drop/10 in WebAdmin > Security"
fi

# ── Cloudflare real-IP support ────────────────────────────────────────
# Without trusted Cloudflare ranges, LSWS anti-DDoS throttles Cloudflare
# itself (522 errors) and logs show Cloudflare IPs instead of visitors.
section_header "Cloudflare Compatibility"
echo -e "${WHITE}Do any sites on this server use Cloudflare? (y/N):${NC}"
read -rp "▶ " cf_choice
if [[ "$cf_choice" =~ ^[Yy]$ ]]; then
    if grep -q '<allow>ALL,127.0.0.1T</allow>' "$LSWS_CONF" 2>/dev/null; then
        process_step "Adding Cloudflare IP ranges as trusted"
        sed -i 's|<allow>ALL,127.0.0.1T</allow>|<allow>ALL, 127.0.0.1T, 103.21.244.0/22T, 103.22.200.0/22T, 103.31.4.0/22T, 104.16.0.0/13T, 104.24.0.0/14T, 108.162.192.0/18T, 131.0.72.0/22T, 141.101.64.0/18T, 162.158.0.0/15T, 172.64.0.0/13T, 173.245.48.0/20T, 188.114.96.0/20T, 190.93.240.0/20T, 197.234.240.0/22T, 198.41.128.0/17T, 199.27.128.0/21T</allow>|' "$LSWS_CONF"
        sed -i 's|<useIpInProxyHeader></useIpInProxyHeader>|<useIpInProxyHeader>2</useIpInProxyHeader>|' "$LSWS_CONF"
        success_msg "Cloudflare ranges trusted; client IP read from proxy header (trusted IPs only)"
    else
        warning_msg "Access-control list already customized — add Cloudflare ranges as trusted in WebAdmin > Security"
    fi
else
    success_msg "Skipped Cloudflare configuration"
fi

# ── LSCache ───────────────────────────────────────────────────────────
section_header "LiteSpeed Cache (LSCache)"
if [ ! -d /home/lscache ] && ! grep -q "cacheStorePath" "$LSWS_CONF" 2>/dev/null; then
    process_step "Setting the server-level cache root policy"
    cd /root || exit 1
    rm -f set_cache_root_policy.sh
    if wget -q https://www.litespeedtech.com/packages/lscache/set_cache_root_policy.sh; then
        bash ./set_cache_root_policy.sh >> "$LOG_FILE" 2>&1 && success_msg "Cache root policy set"
        rm -f /root/set_cache_root_policy.sh
    else
        warning_msg "Could not download set_cache_root_policy.sh — set the cache root from the WHM plugin"
    fi
fi

LSCMCTL="$LSWS_DIR/admin/misc/lscmctl"
if [ -x "$LSCMCTL" ]; then
    process_step "Scanning for WordPress installations"
    "$LSCMCTL" scan >> "$LOG_FILE" 2>&1 && success_msg "WordPress scan completed"

    if [ "$ACCOUNTS" -le 1 ]; then
        process_step "Enabling LSCache for discovered WordPress sites"
        "$LSCMCTL" enable -m >> "$LOG_FILE" 2>&1 \
            && success_msg "LSCache enabled for all discovered WordPress installations" \
            || warning_msg "LSCache mass-enable did not complete — manage it from the WHM LiteSpeed plugin"
    else
        echo; btop "$YELLOW"
        bctr "$YELLOW" "${WHITE}Shared server detected ($ACCOUNTS accounts)"
        bsep "$YELLOW"
        brow "$YELLOW" "${WHITE} Mass-enabling LSCache installs a plugin into every"
        brow "$YELLOW" "${WHITE} customer WordPress site (sites with conflicting cache"
        brow "$YELLOW" "${WHITE} plugins are skipped automatically)."
        bbot "$YELLOW"
        echo -e "${YELLOW}Enable LSCache for ALL WordPress sites? (y/N):${NC}"
        read -rp "▶ " lscache_choice
        if [[ "$lscache_choice" =~ ^[Yy]$ ]]; then
            "$LSCMCTL" enable -m >> "$LOG_FILE" 2>&1 \
                && success_msg "LSCache enabled for all discovered WordPress installations" \
                || warning_msg "LSCache mass-enable did not complete — manage it from the WHM LiteSpeed plugin"
        else
            success_msg "Skipped mass-enable — customers can enable LSCache per site"
        fi
    fi
    log "Note: the LSCache crawler is deliberately NOT enabled (high resource cost, minimal benefit)"
else
    warning_msg "lscmctl not found — manage LSCache from WHM > Plugins > LiteSpeed"
fi

# ── Automatic stable-channel updates ─────────────────────────────────
section_header "Automatic LiteSpeed Updates"
mkdir -p "$LSWS_DIR/autoupdate"
touch "$LSWS_DIR/autoupdate/follow_stable"
if ! crontab -l 2>/dev/null | grep -q "lsup.sh"; then
    (crontab -l 2>/dev/null; echo "0 2 * * * $LSWS_DIR/admin/misc/lsup.sh") | crontab -
    success_msg "Daily stable-channel update check scheduled (02:00)"
else
    success_msg "LiteSpeed update cron already present"
fi

# ── Restart LiteSpeed to apply configuration changes ─────────────────
process_step "Restarting LiteSpeed gracefully"
"$LSWS_DIR/bin/lswsctrl" restart >/dev/null 2>&1
sleep 3
if systemctl is-active --quiet lsws 2>/dev/null || systemctl is-active --quiet lshttpd 2>/dev/null || pgrep -f lshttpd >/dev/null 2>&1; then
    success_msg "LiteSpeed restarted and running"
else
    error_msg "LiteSpeed did not come back up — switch back to Apache with:"
    error_msg "  $LSWS_DIR/admin/misc/cp_switch_ws.sh apache"
    exit 1
fi

# Which server owns port 80?
PORT80_OWNER=$(ss -tlnp 2>/dev/null | grep -w ":80" | grep -o 'litespeed\|lshttpd\|httpd\|apache' | head -1)
case "$PORT80_OWNER" in
    litespeed|lshttpd) success_msg "LiteSpeed is serving port 80" ;;
    httpd|apache)      warning_msg "Apache is still on port 80 — switch with: $LSWS_DIR/admin/misc/cp_switch_ws.sh lsws" ;;
    *)                 log "Port 80 owner not conclusively detected — verify with: lsof -i :80" ;;
esac

# ── Final summary ─────────────────────────────────────────────────────
echo; btop "$BLUE"
bctr "$BLUE" "${GREEN}LITESPEED SETUP COMPLETE"
bsep "$BLUE"
brow "$BLUE" " ${GREEN}• License:${NC} serial in $LSWS_DIR/conf/serial.no (refresh: lshttpd -r)"
brow "$BLUE" " ${GREEN}• WebAdmin:${NC} user admin, password in /root/.lsws_webadmin.pass"
brow "$BLUE" " ${GREEN}• PHP:${NC} lsphp via LSAPI, suEXEC user-home-only, TimeZoneDB built"
brow "$BLUE" " ${GREEN}• HTTP/3:${NC} UDP 443 open in CSF (in/out, IPv4+IPv6)"
brow "$BLUE" " ${GREEN}• LFD:${NC} lsphp binaries ignored (no false process alerts)"
brow "$BLUE" " ${GREEN}• WP protection:${NC} brute-force drop after 10 attempts"
brow "$BLUE" " ${GREEN}• Updates:${NC} stable channel, nightly check at 02:00"
brow "$BLUE" " ${GREEN}• Backups:${NC} $BACKUP_DIR"
bsep "$BLUE"
brow "$BLUE" " ${YELLOW}Rollback to Apache anytime:${NC}"
brow "$BLUE" "   $LSWS_DIR/admin/misc/cp_switch_ws.sh apache"
brow "$BLUE" " ${YELLOW}Restart all detached PHP processes:${NC}"
brow "$BLUE" "   touch $LSWS_DIR/admin/tmp/.lsphp_restart.txt"
bbot "$BLUE"
log "LiteSpeed setup completed"
