#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# EasycPanel Shared Library (lib.sh)
#
# Common helpers used by every EasycPanel script: colors, box drawing,
# logging, backups, OS detection, verified downloads, license checks and
# reusable tuning routines. This file only defines functions and safe
# defaults — sourcing it never performs any action on its own.
#
# Created by Ahtsham Jutt — https://www.ahtshamjutt.com
# ═══════════════════════════════════════════════════════════════════════

# Guard against double-sourcing
[ -n "${EASYCPANEL_LIB_LOADED:-}" ] && return 0
EASYCPANEL_LIB_LOADED=1

# Project mirror — the ONLY approved download source for EasycPanel assets
EASYCPANEL_MIRROR="https://script.ahtshamjutt.com/easycpanel"

# Pinned SHA256 checksums for mirror assets (csf.tgz is frozen upstream —
# ConfigServer is retired, so this archive never changes)
# shellcheck disable=SC2034  # consumed by the scripts that source this library
EASYCPANEL_CSF_SHA256="2ed60f1ef0a49d9b6812e181703ed04b48aa509b9480d643e561dbc35ce10658"

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ── Box-drawing helpers (runtime auto-alignment) ──────────────────────
BOXW=71  # inner box width
_bord() { local b; printf -v b '%*s' "$BOXW" ''; printf '%b%s%s%s%b\n' "$1" "$2" "${b// /─}" "$3" "$NC"; }
btop() { _bord "${1:-$BLUE}" '┌' '┐'; }
bsep() { _bord "${1:-$BLUE}" '├' '┤'; }
bbot() { _bord "${1:-$BLUE}" '└' '┘'; }
# brow BORDER_COLOR CONTENT — box row, padded so borders always align.
# CONTENT may embed color variables; width is computed on visible text.
brow() {
    local raw plain pad
    raw=$(printf '%b' "$2")
    plain=$(printf '%s' "$raw" | sed $'s/\x1b\\[[0-9;]*m//g')
    plain="$plain${plain//[^☕]/}"  # ☕ renders 2 cols wide
    pad=$(( BOXW - ${#plain} ))
    (( pad < 0 )) && pad=0
    printf '%b│%b%s%*s%b│%b\n' "$1" "$NC" "$raw" "$pad" '' "$1" "$NC"
}
# bctr BORDER_COLOR CONTENT — centered box row
bctr() {
    local raw plain lead
    raw=$(printf '%b' "$2")
    plain=$(printf '%s' "$raw" | sed $'s/\x1b\\[[0-9;]*m//g')
    plain="$plain${plain//[^☕]/}"  # ☕ renders 2 cols wide
    lead=$(( (BOXW - ${#plain}) / 2 ))
    (( lead < 0 )) && lead=0
    printf -v raw '%*s%s' "$lead" '' "$raw"
    brow "$1" "$raw"
}

# Default log location — scripts override LOG_FILE after sourcing
: "${LOG_FILE:=/root/easycpanel.log}"

# Function to add a log entry and echo it to the terminal
log() {
    # Add timestamped entry to log file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "${LOG_FILE}"
    # Display clean message without timestamp on screen
    echo -e "${CYAN}$*${NC}"
}

# Function to create a backup of a file (optional 2nd arg: subdirectory
# inside BACKUP_DIR). Requires BACKUP_DIR to be set by the caller.
backup_file() {
    local file="$1"
    local custom_dir="${2:-}"
    local backup_name="${file##*/}"
    local backup_path=""

    if [ -z "${BACKUP_DIR:-}" ]; then
        log "Warning: BACKUP_DIR not set, skipping backup of $file"
        return 1
    fi

    if [ -z "$custom_dir" ]; then
        backup_path="$BACKUP_DIR/$backup_name"
    else
        mkdir -p "$BACKUP_DIR/$custom_dir"
        backup_path="$BACKUP_DIR/$custom_dir/$backup_name"
    fi

    if [ -f "$file" ]; then
        cp "$file" "$backup_path"
        echo "$file => $backup_path" >> "$BACKUP_DIR/backup_manifest.log"
        log "Created backup of $file"
        return 0
    else
        log "Warning: File $file does not exist, nothing to backup"
        return 1
    fi
}

# Function to backup a directory (optional 2nd arg: subdirectory inside
# BACKUP_DIR)
backup_directory() {
    local dir="$1"
    local custom_dir="${2:-}"
    local dirname; dirname=$(basename "$dir")
    local backup_path=""

    if [ -z "${BACKUP_DIR:-}" ]; then
        log "Warning: BACKUP_DIR not set, skipping backup of $dir"
        return 1
    fi

    if [ -z "$custom_dir" ]; then
        backup_path="$BACKUP_DIR/$dirname"
    else
        mkdir -p "$BACKUP_DIR/$custom_dir"
        backup_path="$BACKUP_DIR/$custom_dir/$dirname"
    fi

    if [ -d "$dir" ]; then
        cp -r "$dir" "$backup_path"
        echo "$dir => $backup_path" >> "$BACKUP_DIR/backup_manifest.log"
        log "Created backup of directory $dir"
        return 0
    else
        log "Warning: Directory $dir does not exist, nothing to backup"
        return 1
    fi
}

# Function to display section headers with pause and clear screen.
# Screens only start clearing once the main work begins (either flag).
section_header() {
    if [[ "${INSTALLATION_STARTED:-no}" == "yes" || "${OPTIMIZATION_STARTED:-no}" == "yes" ]]; then
        clear
    fi

    echo; btop "$BLUE"
    brow "$BLUE" "${WHITE} $1"
    bbot "$BLUE"
    log "$1"

    sleep 1
}

# Function to display process steps
process_step() {
    echo -e "${YELLOW}➤${NC} $*"
    sleep 0.3
}

# Function to display success message
success_msg() {
    echo -e "${GREEN}✓${NC} $*"
    log "$*"
}

# Function to display error message
error_msg() {
    echo -e "${RED}✗${NC} $*"
    log "ERROR: $*"
}

# Function to display warning message
warning_msg() {
    echo -e "${YELLOW}⚠${NC} $*"
    log "WARNING: $*"
}

# Function to display progress animation
show_progress() {
    echo -ne "${YELLOW}Processing${NC}"
    for _ in {1..5}; do
        echo -ne "${YELLOW}.${NC}"
        sleep 0.2
    done
    echo -e ""
}

# Abort unless running as root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        error_msg "This script must be run as root!"
        exit 1
    fi
}

# Function to check OS compatibility (entry-menu gate)
check_os_compatibility() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
        VERSION_ID=$VERSION_ID
        MAJOR_VERSION=${VERSION_ID%%.*}
    else
        echo -e "${RED}✗${NC} Cannot determine OS. /etc/os-release file not found."
        exit 1
    fi

    if [[ "$OS_NAME" == "almalinux" && ("$MAJOR_VERSION" == "8" || "$MAJOR_VERSION" == "9") ]] ||
       [[ "$OS_NAME" == "cloudlinux" && ("$MAJOR_VERSION" == "8" || "$MAJOR_VERSION" == "9") ]]; then
        echo -e "${GREEN}✓${NC} Compatible OS detected: $OS_NAME $VERSION_ID"
        sleep 1
    else
        echo -e "${RED}✗${NC} Incompatible OS detected: $OS_NAME $VERSION_ID"
        echo -e "${YELLOW}This script is designed to work only with:${NC}"
        echo -e "${WHITE}- AlmaLinux 8.x${NC}"
        echo -e "${WHITE}- AlmaLinux 9.x${NC}"
        echo -e "${WHITE}- CloudLinux 8.x${NC}"
        echo -e "${WHITE}- CloudLinux 9.x${NC}"
        exit 1
    fi
}

# Function to detect OS and version, and set the PHP version lists
# shellcheck disable=SC2034  # PHP version variables are consumed by the sourcing scripts
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
        VERSION_ID=$VERSION_ID
        # Extract major version number
        MAJOR_VERSION=${VERSION_ID%%.*}

        # Set PHP versions based on OS
        if [[ "$OS_NAME" == "almalinux" || "$OS_NAME" == "cloudlinux" ]]; then
            if [[ "$MAJOR_VERSION" == "8" ]]; then
                # For AlmaLinux/CloudLinux 8
                PHP_VERSIONS=("ea-php74" "ea-php80" "ea-php81" "ea-php82" "ea-php83" "ea-php84")
                IMAGICK_COMPATIBLE=("ea-php74" "ea-php80" "ea-php81" "ea-php82")
                DEFAULT_PHP="ea-php83"
            elif [[ "$MAJOR_VERSION" == "9" ]]; then
                # For AlmaLinux/CloudLinux 9
                PHP_VERSIONS=("ea-php80" "ea-php81" "ea-php82" "ea-php83" "ea-php84")
                IMAGICK_COMPATIBLE=("ea-php80" "ea-php81" "ea-php82")
                DEFAULT_PHP="ea-php83"
            else
                error_msg "Unsupported version: $OS_NAME $VERSION_ID"
                exit 1
            fi

            success_msg "Detected $OS_NAME $VERSION_ID"
            log "Setting PHP versions: ${PHP_VERSIONS[*]}"
            log "ImageMagick compatible PHP versions: ${IMAGICK_COMPATIBLE[*]}"
        else
            error_msg "Unsupported OS: $OS_NAME"
            exit 1
        fi
    else
        error_msg "Cannot determine OS. /etc/os-release file not found."
        exit 1
    fi
}

# Function to detect current SSH port
detect_ssh_port() {
    # Try to get SSH port from sshd_config
    CURRENT_SSH_PORT=$(grep -E "^Port\s+[0-9]+" /etc/ssh/sshd_config | awk '{print $2}')

    # If not found in config, use default port 22
    if [ -z "$CURRENT_SSH_PORT" ]; then
        CURRENT_SSH_PORT=22
        log "SSH port not explicitly set in sshd_config, assuming default port 22"
    else
        log "Current SSH port detected: $CURRENT_SSH_PORT"
    fi

    return 0
}

# download_verified FILENAME [SHA256]
# Downloads FILENAME from the project mirror into the current directory.
# When a SHA256 is given the file is verified and removed on mismatch.
download_verified() {
    local file="$1"
    local sha="${2:-}"
    rm -f "$file"
    if ! wget -q "$EASYCPANEL_MIRROR/$file"; then
        error_msg "Download failed: $EASYCPANEL_MIRROR/$file"
        return 1
    fi
    if [ -n "$sha" ]; then
        if ! echo "$sha  $file" | sha256sum -c - >/dev/null 2>&1; then
            error_msg "Checksum mismatch for $file — refusing to use it"
            rm -f "$file"
            return 1
        fi
        log "Checksum verified for $file"
    fi
    return 0
}

# Validate the cPanel license and warn about tier/account mismatches.
# Warning-only: never aborts the run.
check_cpanel_license() {
    if [ ! -x /usr/local/cpanel/cpkeyclt ]; then
        log "cPanel not installed yet — skipping license check"
        return 0
    fi

    process_step "Validating cPanel license"
    if /usr/local/cpanel/cpkeyclt >/dev/null 2>&1; then
        success_msg "cPanel license validated with the license server"
    else
        warning_msg "cPanel license could not be validated (cpkeyclt failed)"
    fi

    local ip resp pkg accounts limit=0
    ip=$(cat /var/cpanel/mainip 2>/dev/null)
    [ -z "$ip" ] && ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$ip" ] && { warning_msg "Could not determine server IP — skipped license tier check"; return 0; }

    resp=$(curl -s --max-time 10 "https://verify.cpanel.net/api/ipaddrs?ip=$ip" 2>/dev/null)
    if [ -z "$resp" ]; then
        warning_msg "Could not reach verify.cpanel.net — skipped license tier check"
        return 0
    fi

    if echo "$resp" | grep -q '"valid":1'; then
        pkg=$(echo "$resp" | grep -o '"package":"[^"]*"' | head -1 | cut -d'"' -f4)
        success_msg "Active cPanel license found: ${pkg:-unknown package}"
        if echo "$resp" | grep -q '"istrial":1'; then
            warning_msg "This is a TRIAL license — purchase a full license before production use"
        fi
        case "$pkg" in
            *PREMIER*|*premier*) limit=100 ;;
            *SOLO*|*solo*)       limit=1 ;;
            *ADMIN*|*admin*)     limit=5 ;;
            *PRO*|*pro*)         limit=30 ;;
        esac
        accounts=$(find /var/cpanel/users -maxdepth 1 -type f 2>/dev/null | wc -l)
        if [ "$limit" -gt 0 ] && [ "$accounts" -gt "$limit" ]; then
            warning_msg "Server has $accounts cPanel accounts but this tier includes $limit — extra accounts bill as overage"
        elif [ "$limit" -gt 0 ]; then
            log "License tier includes $limit account(s); server currently has $accounts"
        fi
    else
        warning_msg "No active cPanel license found for IP $ip (verify.cpanel.net)"
    fi
    return 0
}

# Secure /tmp with noexec,nosuid using cPanel's own securetmp tool
secure_tmp() {
    if [ ! -x /scripts/securetmp ]; then
        warning_msg "cPanel securetmp not found — skipping /tmp hardening"
        return 0
    fi
    if mount | grep -E '\s/tmp\s' | grep -q noexec; then
        success_msg "/tmp already mounted with noexec — no change needed"
        return 0
    fi
    process_step "Securing /tmp with noexec,nosuid (cPanel securetmp)"
    if /scripts/securetmp --auto >/dev/null 2>&1; then
        success_msg "/tmp secured with noexec,nosuid"
    else
        warning_msg "securetmp did not complete — /tmp hardening skipped"
    fi
    return 0
}

# Kernel network & memory tuning: connection queues, swappiness, BBR
# congestion control (when the kernel supports it) and transparent
# hugepages off (recommended for MySQL/MariaDB).
apply_kernel_tuning() {
    process_step "Applying kernel network and memory tuning"

    local bbr_lines=""
    modprobe tcp_bbr 2>/dev/null
    if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        bbr_lines=$'net.core.default_qdisc = fq\nnet.ipv4.tcp_congestion_control = bbr'
        log "BBR congestion control available — enabling"
    else
        log "BBR not available on this kernel — keeping default congestion control"
    fi

    cat > /etc/sysctl.d/99-easycpanel.conf << SYSEOF
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_fin_timeout = 30
net.core.somaxconn = 8192
vm.swappiness = 10
${bbr_lines}
SYSEOF
    sysctl --system >/dev/null 2>&1

    # Disable transparent hugepages now and at every boot (MySQL/MariaDB
    # latency-spike prevention)
    cat > /etc/systemd/system/easycpanel-thp.service << 'THPEOF'
[Unit]
Description=EasycPanel: disable transparent hugepages
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled; echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=multi-user.target
THPEOF
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable --now easycpanel-thp.service >/dev/null 2>&1

    success_msg "Kernel tuning applied (sysctl, swappiness, hugepages${bbr_lines:+, BBR})"
    return 0
}

# Opcache tuning for every installed EA-PHP version
tune_php_opcache() {
    local dir count=0
    for dir in /opt/cpanel/ea-php*/root/etc/php.d; do
        [ -d "$dir" ] || continue
        cat > "$dir/99-easycpanel-opcache.ini" << 'OPEOF'
; EasycPanel opcache tuning
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=32
opcache.max_accelerated_files=50000
opcache.validate_timestamps=1
opcache.revalidate_freq=60
OPEOF
        count=$((count + 1))
    done
    if [ "$count" -gt 0 ]; then
        /scripts/restartsrv_apache_php_fpm >/dev/null 2>&1
        success_msg "Opcache tuned for $count PHP version(s)"
    else
        warning_msg "No EA-PHP installations found — opcache tuning skipped"
    fi
    return 0
}

# Mail server security & deliverability: force outbound mail through
# Exim where it is logged and rate-limited, reject the bulk of spam at
# SMTP connect time, ensure DKIM/SPF on every account, trim resource
# wasters and verify rDNS.
secure_mail_server() {
    # 1. Outbound: block direct port-25 connections from scripts and
    # compromised accounts. Port 25 only — 465/587 stay open because
    # customer applications legitimately send through external SMTP
    # providers with authentication.
    if [ -f /etc/csf/csf.conf ]; then
        [ -n "${BACKUP_DIR:-}" ] && backup_file /etc/csf/csf.conf mail
        sed -i 's/^SMTP_BLOCK = ".*"/SMTP_BLOCK = "1"/' /etc/csf/csf.conf
        sed -i 's/^SMTP_ALLOWLOCAL = ".*"/SMTP_ALLOWLOCAL = "1"/' /etc/csf/csf.conf
        sed -i 's/^SMTP_PORTS = ".*"/SMTP_PORTS = "25"/' /etc/csf/csf.conf
        csf -r >/dev/null 2>&1
        success_msg "Direct port-25 sending blocked — all mail now goes through Exim (logged and rate-limited)"
    fi

    # 2. Inbound: connect-time rejection via Exim ACLs (RBLs kill most
    # spam before SpamAssassin spends CPU on it)
    if [ -f /etc/exim.conf.localopts ]; then
        [ -n "${BACKUP_DIR:-}" ] && backup_file /etc/exim.conf.localopts mail
        cp -f /etc/exim.conf.localopts /etc/exim.conf.localopts.pre-easycpanel
        local kv key
        for kv in acl_spamhaus_rbl=1 acl_spamcop_rbl=1 acl_dictionary_attack=1 acl_ratelimit=1; do
            key=${kv%%=*}
            if grep -q "^${key}=" /etc/exim.conf.localopts; then
                sed -i "s/^${key}=.*/${kv}/" /etc/exim.conf.localopts
            else
                echo "$kv" >> /etc/exim.conf.localopts
            fi
        done
        if /scripts/buildeximconf >/dev/null 2>&1 && /scripts/restartsrv_exim >/dev/null 2>&1; then
            success_msg "Exim ACLs on: Spamhaus/SpamCop RBLs, dictionary-attack protection, SMTP ratelimiting"
        else
            cp -f /etc/exim.conf.localopts.pre-easycpanel /etc/exim.conf.localopts
            /scripts/buildeximconf >/dev/null 2>&1
            /scripts/restartsrv_exim >/dev/null 2>&1
            warning_msg "Exim rebuild failed — ACL changes rolled back; review WHM > Exim Configuration Manager"
        fi
    fi

    # 3. DKIM + SPF for all existing accounts (new accounts get them at
    # creation by cPanel default)
    local u count=0
    while IFS= read -r u; do
        [ -x /usr/local/cpanel/bin/dkim_keys_install ] && /usr/local/cpanel/bin/dkim_keys_install "$u" >/dev/null 2>&1
        [ -x /usr/local/cpanel/bin/spf_installer ] && /usr/local/cpanel/bin/spf_installer "$u" >/dev/null 2>&1
        count=$((count + 1))
    done < <(find /var/cpanel/users -maxdepth 1 -type f -printf '%f\n' 2>/dev/null)
    if [ "$count" -gt 0 ]; then
        success_msg "DKIM and SPF records ensured for $count account(s)"
    else
        log "No cPanel accounts yet — new accounts get DKIM/SPF automatically"
    fi

    # 4. Resource trims: BoxTrapper wastes CPU and generates backscatter;
    # unbounded Exim stats bloat the database on busy servers
    whmapi1 set_tweaksetting key=skipboxtrapper value=1 >/dev/null 2>&1
    whmapi1 set_tweaksetting key=exim_retention_days value=30 >/dev/null 2>&1
    whmapi1 set_tweaksetting key=skipspamassassin value=0 >/dev/null 2>&1
    success_msg "BoxTrapper off, SpamAssassin available, Exim stats retention 30 days"

    # 5. Greylisting is a trade-off (cuts spam sharply, delays all
    # first-contact mail) — owner's decision
    echo -e "${WHITE}Enable cPanel Greylisting? Cuts spam sharply but delays first-contact mail (y/N):${NC}"
    read -rp "▶ " grey_choice
    if [[ "$grey_choice" =~ ^[Yy]$ ]]; then
        whmapi1 enable_cpgreylist >/dev/null 2>&1 \
            && success_msg "Greylisting enabled" \
            || warning_msg "Could not enable Greylisting — see WHM > Greylisting"
    else
        success_msg "Greylisting left off"
    fi

    # 6. rDNS/PTR check — the single most common deliverability failure
    local mainip ptr hn
    mainip=$(cat /var/cpanel/mainip 2>/dev/null)
    hn=$(hostname -f 2>/dev/null || hostname)
    if [ -n "$mainip" ] && command -v dig >/dev/null 2>&1; then
        ptr=$(dig +short -x "$mainip" 2>/dev/null | sed 's/\.$//' | head -1)
        if [ -z "$ptr" ]; then
            warning_msg "No PTR (rDNS) record for $mainip — request one from your provider or outbound mail will be junked"
        elif [ "$ptr" != "$hn" ]; then
            warning_msg "PTR for $mainip is '$ptr' but the hostname is '$hn' — align them for deliverability"
        else
            success_msg "PTR record matches hostname ($hn)"
        fi
    fi
    return 0
}

# Cache daemon hardening shared by all branches: keep Redis/Memcached
# out of LFD process alerts, their ports closed to the public, verify
# the localhost binding, and right-size the memcached cache.
secure_cache_daemons() {
    local line changed=false
    if [ -f /etc/csf/csf.pignore ]; then
        for line in 'exe:/usr/bin/redis-server' 'exe:/usr/bin/memcached'; do
            if ! grep -qxF "$line" /etc/csf/csf.pignore; then
                echo "$line" >> /etc/csf/csf.pignore
                changed=true
            fi
        done
        # Cache ports must never be publicly reachable
        if grep -E '^TCP_IN' /etc/csf/csf.conf 2>/dev/null | grep -Eqw '6379|11211'; then
            sed -i '/^TCP_IN/ s/,6379\b//; /^TCP_IN/ s/,11211\b//' /etc/csf/csf.conf
            csf -r >/dev/null 2>&1
            changed=true
        fi
        [ "$changed" = true ] && systemctl restart lfd >/dev/null 2>&1
        success_msg "Cache daemons ignored by LFD; ports 6379/11211 closed to the public"
    fi

    if [ -f /etc/sysconfig/memcached ]; then
        # The OPTIONS edit elsewhere only matches pristine files — verify
        # the localhost binding actually took effect
        if ! grep -q '127.0.0.1' /etc/sysconfig/memcached; then
            warning_msg "Memcached is NOT bound to localhost — check OPTIONS in /etc/sysconfig/memcached"
        fi
        # Right-size the cache on servers with RAM to spare
        local ram_gb size
        ram_gb=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
        if [ "$ram_gb" -ge 4 ] && grep -q '^CACHESIZE="64"' /etc/sysconfig/memcached; then
            size=128
            [ "${SERVER_TYPE:-shared}" = "personal" ] && size=256
            sed -i "s/^CACHESIZE=\"64\"/CACHESIZE=\"$size\"/" /etc/sysconfig/memcached
            systemctl restart memcached >/dev/null 2>&1
            success_msg "Memcached cache size raised to ${size}MB"
        fi
    fi
    return 0
}

# Install the newest stable PHP versions when EasyApache provides them,
# with the same extension set as the EasyApache profiles. Versions not
# yet published by cPanel are skipped gracefully, so this stays correct
# as new PHP releases appear.
install_latest_php() {
    local ver ext pkgs
    # shellcheck disable=SC2043  # single-item list on purpose; append future PHP versions here
    for ver in ea-php85; do
        if [ -d "/opt/cpanel/$ver" ]; then
            success_msg "$ver already installed"
            continue
        fi
        if yum -q list available "$ver" >/dev/null 2>&1; then
            process_step "Installing $ver with the full extension set"
            pkgs="$ver ${ver}-runtime ${ver}-pear"
            for ext in bcmath calendar cli common curl devel exif fileinfo fpm ftp gd gettext iconv litespeed mbstring memcached mysqlnd opcache pdo posix soap sockets xml zip; do
                pkgs="$pkgs ${ver}-php-${ext}"
            done
            # shellcheck disable=SC2086
            if yum install -y $pkgs >/dev/null 2>&1; then
                success_msg "$ver installed with required extensions"
                PHP_VERSIONS+=("$ver")
            else
                warning_msg "$ver install failed — continuing without it"
            fi
        else
            log "$ver not yet available in EasyApache — skipping"
        fi
    done
    return 0
}

# PHP-FPM pool tuning computed from server RAM and usage profile, plus
# actually enabling FPM for all current and future domains (installing
# the packages alone does not turn FPM on). Shared servers use ondemand
# (zero idle memory across many pools); personal servers use dynamic
# (warm workers, no process-start latency for a busy site). open_basedir
# is applied per pool so accounts cannot read outside their home.
tune_php_fpm_pools() {
    local ram_gb mc profile="${SERVER_TYPE:-shared}"
    ram_gb=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
    [ "$ram_gb" -lt 1 ] && ram_gb=1

    # PHP-FPM needs roughly 2 GB RAM minimum (~30 MB per domain)
    if [ "$ram_gb" -lt 2 ]; then
        warning_msg "Server has under 2 GB RAM — keeping cPanel's default PHP-FPM configuration"
        return 0
    fi

    if [ "$profile" = "personal" ]; then
        mc=$(( ram_gb * 6 ))
        [ "$mc" -lt 15 ] && mc=15
        [ "$mc" -gt 80 ] && mc=80
    else
        mc=$(( ram_gb * 3 ))
        [ "$mc" -lt 10 ] && mc=10
        [ "$mc" -gt 40 ] && mc=40
    fi

    mkdir -p /var/cpanel/ApachePHPFPM
    if [ -f /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml ] && [ -n "${BACKUP_DIR:-}" ]; then
        backup_file /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml
    fi

    if [ "$profile" = "personal" ]; then
        cat > /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml << FPMEOF
---
pm: dynamic
pm_max_children: $mc
pm_start_servers: 3
pm_min_spare_servers: 2
pm_max_spare_servers: 8
pm_max_requests: 500
pm_process_idle_timeout: 10
php_value_open_basedir: { name: 'php_value[open_basedir]', value: "[% documentroot %]:[% homedir %]:/var/cpanel/php/sessions/[% ea_php_version %]:/tmp:/var/tmp" }
FPMEOF
    else
        cat > /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml << FPMEOF
---
pm: ondemand
pm_max_children: $mc
pm_max_requests: 500
pm_process_idle_timeout: 10
php_value_open_basedir: { name: 'php_value[open_basedir]', value: "[% documentroot %]:[% homedir %]:/var/cpanel/php/sessions/[% ea_php_version %]:/tmp:/var/tmp" }
FPMEOF
    fi

    # Turn FPM on for new accounts and convert every existing domain
    whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm=1 >/dev/null 2>&1
    whmapi1 convert_all_domains_to_fpm >/dev/null 2>&1

    if [ -x /scripts/php_fpm_config ]; then
        /scripts/php_fpm_config --rebuild >/dev/null 2>&1
        if [ "$profile" = "personal" ]; then
            success_msg "PHP-FPM enabled for all domains: pm=dynamic, max_children=$mc, open_basedir on"
        else
            success_msg "PHP-FPM enabled for all domains: pm=ondemand, max_children=$mc, open_basedir on"
        fi
        log "If pools saturate later, check: grep 'reached max_children' /opt/cpanel/ea-php*/root/usr/var/log/php-fpm/*"
    else
        warning_msg "php_fpm_config not found — FPM pool defaults written but not rebuilt"
    fi
    return 0
}
