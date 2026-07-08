#!/bin/bash
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
LOG_FILE="/root/panelbot-optimization.log"

# Create backup directory structure
BACKUP_DIR="/backup/panelbot-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Check for Root Privileges
require_root

# Clear the screen for a clean look
clear

# Display a compact banner
btop "$BLUE"
bctr "$BLUE" "${GREEN}cPanel Optimization, Hardening & Security"
bctr "$BLUE" "${YELLOW}Created by Ahtsham Jutt"
bctr "$BLUE" "${WHITE}Website: ahtshamjutt.com | me@ahtshamjutt.com"
bctr "$BLUE" "${CYAN}Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕"
bbot "$BLUE"

# Display optimization time notice
echo; btop "$YELLOW"
bctr "$YELLOW" "${WHITE}IMPORTANT NOTICE"
bsep "$YELLOW"
brow "$YELLOW" "${WHITE} • This script will optimize your existing cPanel server"
brow "$YELLOW" "${WHITE} • All modified files will be backed up to:"
brow "$YELLOW" "${WHITE}   ${GREEN}$BACKUP_DIR${WHITE}"
brow "$YELLOW" ""
brow "$YELLOW" "${WHITE} • The optimization process may take 15-30 minutes"
brow "$YELLOW" "${WHITE} • Some services will be restarted during the process"
bbot "$YELLOW"
sleep 5

# Detect OS and set PHP versions
section_header "Detecting Operating System"
detect_os

# Detect current SSH port
detect_ssh_port

# Validate the cPanel license and tier
check_cpanel_license

# Collect information
section_header "Required Information"

btop "$CYAN"
brow "$CYAN" "${WHITE} Please provide your email address for server alerts:"
bbot "$CYAN"
while true; do
    read -rp "▶ " email
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && break
    echo -e "${RED}✗${NC} Invalid email address, please try again."
done
log "Email set to: $email"

echo; btop "$CYAN"
brow "$CYAN" "${WHITE} Server Usage Type:"
bsep "$CYAN"
brow "$CYAN" "${WHITE} This affects how Apache and MySQL resources are allocated"
bbot "$CYAN"
echo -e "${WHITE}How will this server be used?${NC}"
echo -e "${GREEN}1.${NC} Personal Server ${WHITE}(for personal websites, optimized dynamically)${NC}"
echo -e "${GREEN}2.${NC} Shared Hosting Server ${WHITE}(for hosting multiple client accounts)${NC}"
read -rp "▶ " server_usage_choice

if [[ "$server_usage_choice" == "2" ]]; then
    SERVER_TYPE="shared"
    success_msg "Configuring for Shared Hosting Server (static resource allocation)"
else
    SERVER_TYPE="personal"
    success_msg "Configuring for Personal Server (dynamic resource allocation)"
fi
log "Server type set to: $SERVER_TYPE"

# SSH port configuration
echo; btop "$CYAN"
brow "$CYAN" "${WHITE} SSH Port Configuration:"
bsep "$CYAN"
brow "$CYAN" "${YELLOW} Current SSH port: $CURRENT_SSH_PORT"
bbot "$CYAN"
echo -e "${WHITE}Would you like to:${NC}"
echo -e "${GREEN}1.${NC} Keep current SSH port: $CURRENT_SSH_PORT"
echo -e "${GREEN}2.${NC} Change SSH port ${YELLOW}(requires updating firewall rules)${NC}"
read -rp "▶ " ssh_change_choice

if [[ "$ssh_change_choice" == "2" ]]; then
    echo; btop "$CYAN"
    brow "$CYAN" "${WHITE} Choose new SSH port:"
    bbot "$CYAN"
    echo -e "${YELLOW}1.${NC} Use default SSH port 22 ${YELLOW}(Not Recommended)${NC}"
    echo -e "${GREEN}2.${NC} Use port 2200 ${GREEN}(Recommended)${NC}"
    echo -e "${GREEN}3.${NC} Use a randomly generated secure port ${GREEN}(Recommended)${NC}"
    read -rp "▶ " ssh_port_choice

    # Generate random SSH port between 1500 and 50000
    RANDOM_SSH_PORT=$(( $RANDOM % 48500 + 1500 ))

    case "$ssh_port_choice" in
        1)
            SSH_PORT=22
            warning_msg "Using default SSH port 22 (not recommended for security)"
            ;;
        2)
            SSH_PORT=2200
            success_msg "Will configure SSH to use port 2200"
            ;;
        3)
            SSH_PORT=$RANDOM_SSH_PORT
            success_msg "Will configure SSH to use secure random port: $SSH_PORT"
            ;;
        *)
            SSH_PORT=$RANDOM_SSH_PORT
            warning_msg "Invalid choice. Using randomly generated port: $SSH_PORT"
            ;;
    esac
    
    CHANGE_SSH_PORT=true
    log "Will change SSH port from $CURRENT_SSH_PORT to $SSH_PORT"
else
    SSH_PORT=$CURRENT_SSH_PORT
    CHANGE_SSH_PORT=false
    success_msg "Keeping current SSH port: $SSH_PORT"
fi

# Fetch server's main IP address
section_header "Fetching Server Information"
process_step "Detecting server's main IP address"
SERVER_IP=$(hostname -I | awk '{print $1}')
success_msg "Server IP detected: $SERVER_IP"

HOSTNAME=$(hostname)
success_msg "Current hostname: $HOSTNAME"

# Display information summary and proceed
echo; btop "$CYAN"
brow "$CYAN" "${WHITE} Optimization will proceed with the following settings:"
bsep "$CYAN"
brow "$CYAN" "${WHITE} Email: ${GREEN}$email"
brow "$CYAN" "${WHITE} Server IP: ${GREEN}$SERVER_IP"
brow "$CYAN" "${WHITE} Server Type: ${GREEN}$([ "$SERVER_TYPE" == "personal" ] && echo "Personal" || echo "Shared Hosting")"
brow "$CYAN" "${WHITE} SSH Port: ${GREEN}$SSH_PORT${NC} $([ "$CHANGE_SSH_PORT" == "true" ] && echo "${YELLOW}(Will be changed)" || echo "${GREEN}(No change)")"
brow "$CYAN" "${WHITE} Backup Directory: ${GREEN}$BACKUP_DIR"
bbot "$CYAN"

log "Optimization will proceed with: Email=$email, IP=$SERVER_IP, Type=$SERVER_TYPE, SSH Port=$SSH_PORT"
sleep 4

# Main optimization begins
# Now we can start clearing the screen for new sections
OPTIMIZATION_STARTED="yes"
clear
section_header "Starting cPanel Optimization and Security Configuration"
warning_msg "This process will take some time. Please be patient."

# Update system packages
section_header "Updating System Packages"
process_step "Running system update"
sudo dnf update -y
success_msg "System update completed"

process_step "Installing wget and nano if needed"
sudo dnf install wget nano -y
success_msg "Wget and nano text editor installed/verified"

# Configure network and security settings
section_header "Configuring Network and Security Settings"

# Only disable NetworkManager on AlmaLinux/CloudLinux 8, keep it on version 9
if [[ "$MAJOR_VERSION" == "8" ]]; then
    process_step "Stopping and disabling NetworkManager (required for cPanel on AlmaLinux/CloudLinux 8)"
    systemctl stop NetworkManager
    systemctl disable NetworkManager
    success_msg "NetworkManager disabled"
else
    process_step "Keeping NetworkManager enabled (supported on AlmaLinux/CloudLinux 9)"
    success_msg "NetworkManager kept active (compatible with cPanel on version 9)"
fi

process_step "Checking SELinux status"
SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Unknown")
if [[ "$SELINUX_STATUS" == "Enforcing" ]]; then
    backup_file "/etc/selinux/config"
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    success_msg "SELinux will be disabled after reboot (current: $SELINUX_STATUS)"
else
    success_msg "SELinux is already disabled or permissive (current: $SELINUX_STATUS)"
fi

section_header "Detecting Network Interface"
process_step "Detecting network interface"

# Try to find the interface associated with the main IP first (most reliable)
INTERFACE=$(ip -o addr show | grep "$SERVER_IP" | awk '{print $2}' | head -1)

# If not found, try common virtualization interfaces and then default route
if [ -z "$INTERFACE" ]; then
    # Try virtualization-specific interfaces (OpenVZ/Virtuozzo)
    INTERFACE=$(ip a | grep -E 'venet0|venet0:0' | awk '{print $2}' | cut -d ':' -f 1 | head -1)
    
    # Try common cloud/VPS interfaces if still not found
    if [ -z "$INTERFACE" ]; then
        # Try default route interface (works in most environments)
        INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        
        # Last resort - first non-loopback interface
        if [ -z "$INTERFACE" ]; then
            INTERFACE=$(ip -o link show | grep -v 'lo' | awk -F': ' '{print $2}' | head -1)
        fi
    fi
fi

# Fallback if all detection methods fail
if [ -z "$INTERFACE" ]; then
    warning_msg "Could not detect network interface. Using default 'eth0'"
    INTERFACE="eth0"
else
    success_msg "Network interface detected: $INTERFACE"
fi

# Auto-tune Apache and MySQL
section_header "Auto-tuning Apache and MySQL"
process_step "Detecting system resources for optimization"

# 1. Detect Total System RAM (MB)
TOTAL_MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
log "Total RAM detected: ${TOTAL_MEM_MB} MB"

# 2. Set resource allocation ratios
APACHE_RATIO=0.35
MYSQL_RATIO=0.30

# 3. Calculate memory allocations
APACHE_MB=$(awk -v mem="$TOTAL_MEM_MB" -v r="$APACHE_RATIO" 'BEGIN{printf "%d", mem*r}')
MYSQL_MB=$(awk -v mem="$TOTAL_MEM_MB" -v r="$MYSQL_RATIO" 'BEGIN{printf "%d", mem*r}')

log "Allocating $APACHE_MB MB to Apache/PHP-FPM, $MYSQL_MB MB to MySQL, rest for OS."

# 4. Configure Apache Event MPM based on server type
if [[ "$SERVER_TYPE" == "personal" ]]; then
    # Dynamic configuration for personal server
    process_step "Using dynamic Apache tuning for personal server"
    
    # Calculate max workers based on average memory per slot
    AVG_WORKER_MB=50
    CALC_MAXWORKERS=$(( APACHE_MB / AVG_WORKER_MB ))
    
    # Set reasonable minimums
    if [ "$CALC_MAXWORKERS" -lt 20 ]; then
        CALC_MAXWORKERS=20
    fi
    
    # Optional concurrency cap
    MAX_CONCURRENCY_CAP=2000
    if [ "$CALC_MAXWORKERS" -gt "$MAX_CONCURRENCY_CAP" ]; then
        CALC_MAXWORKERS=$MAX_CONCURRENCY_CAP
    fi
    
    # Adjust ThreadsPerChild & ServerLimit
    THREADS_PER_CHILD=64
    SERVER_LIMIT=1
    
    if [ "$CALC_MAXWORKERS" -lt 64 ]; then
        # concurrency <64 => single process with that many threads
        THREADS_PER_CHILD=$CALC_MAXWORKERS
        SERVER_LIMIT=1
        FINAL_MRW=$CALC_MAXWORKERS
    else
        # concurrency >=64 => keep threads=64, spawn multiple processes as needed
        SERVER_LIMIT=$(( (CALC_MAXWORKERS + 63) / 64 ))
        
        # Cap at 32 child processes (concurrency up to 2048)
        MAX_SERVERLIMIT=32
        if [ "$SERVER_LIMIT" -gt "$MAX_SERVERLIMIT" ]; then
            SERVER_LIMIT=$MAX_SERVERLIMIT
        fi
        
        FINAL_MRW=$(( SERVER_LIMIT * 64 ))
    fi
    
    log "Dynamic Apache configuration: ThreadsPerChild=$THREADS_PER_CHILD, ServerLimit=$SERVER_LIMIT, MaxRequestWorkers=$FINAL_MRW"
else
    # Static configuration for shared hosting
    process_step "Using static Apache tuning for shared hosting server"
    
    # Standard shared hosting values
    SERVER_LIMIT=16
    THREADS_PER_CHILD=25
    FINAL_MRW=400
    
    log "Static Apache configuration: ThreadsPerChild=$THREADS_PER_CHILD, ServerLimit=$SERVER_LIMIT, MaxRequestWorkers=$FINAL_MRW"
fi

# Backup and create Apache configuration
APACHE_CONF="/etc/apache2/conf.d/includes/pre_main_global.conf"
backup_file "$APACHE_CONF"

cat <<EOL > "$APACHE_CONF"
<IfModule event.c>
    ServerLimit              $SERVER_LIMIT
    StartServers             3
    MinSpareThreads          25
    MaxSpareThreads          75
    ThreadsPerChild          $THREADS_PER_CHILD
    MaxRequestWorkers        $FINAL_MRW
    MaxConnectionsPerChild   0
</IfModule>
EOL

# Backup and update EA4 YAML configuration
backup_file "/etc/cpanel/ea4/ea4.conf"
sed -i \
  -e "s/\(maxclients[\" ]*:\)\s[0-9\"]\+/\1 $FINAL_MRW/" \
  -e 's/\(maxrequestsperchild[" ]*:\)\s[0-9"]\+/\1 0/' \
  -e "s/\(serverlimit[\" ]*:\)\s[0-9\"]\+/\1 $SERVER_LIMIT/" \
  -e 's/\(startservers[" ]*:\)\s[0-9"]\+/\1 3/' \
  -e "s/\(threadsperchild[\" ]*:\)\s[0-9\"]\+/\1 $THREADS_PER_CHILD/" \
  -e 's/\(symlink_protect[" ]*:\)\s[A-Za-z0-9"]\+/\1 "On"/' \
  /etc/cpanel/ea4/ea4.conf

process_step "Rebuilding and restarting Apache"
/scripts/rebuildhttpdconf
/scripts/restartsrv_httpd
success_msg "Apache configured with MaxRequestWorkers = $FINAL_MRW"

# 5. Configure MySQL
process_step "Tuning MySQL configuration"

# Calculate appropriate buffer pool size
if [[ "$SERVER_TYPE" == "personal" ]]; then
    # Dynamic MySQL tuning
    MYSQL_GB=$(awk -v mb="$MYSQL_MB" 'BEGIN { printf "%.1f", mb/1024 }')
    MYSQL_GB_INT=$(awk -v mb="$MYSQL_MB" 'BEGIN { printf "%.0f", mb/1024 }')
    
    # Ensure minimum buffer size
    if [ "$(awk -v g="$MYSQL_GB" 'BEGIN{print (g<1)?1:0}')" = "1" ]; then
        BPOOL="512M"
    else
        BPOOL="${MYSQL_GB_INT}G"
    fi
    
    process_step "Setting MySQL InnoDB buffer pool size to $BPOOL (dynamic)"
else
    # Static MySQL tuning for shared hosting
    if [ $TOTAL_MEM_MB -ge 32768 ]; then  # ≥32GB
        BPOOL="8G"
    elif [ $TOTAL_MEM_MB -ge 16384 ]; then  # ≥16GB
        BPOOL="4G"
    else
        BPOOL="2G"
    fi
    
    process_step "Setting MySQL InnoDB buffer pool size to $BPOOL (static)"
fi

# Configure EasyApache4 PHP versions
section_header "Configuring PHP Settings"

# Install the newest stable PHP version when EasyApache provides it
install_latest_php

# Get installed PHP versions
INSTALLED_PHP_VERSIONS=$(whmapi1 php_get_installed_versions | grep ea-php | awk '{print $2}' | tr '\n' ' ')

# Define PHP directives to set
PHP_DIRECTIVES=(
    "memory_limit:256M"
    "post_max_size:512M"
    "upload_max_filesize:512M"
    "max_input_vars:10000"
)

# Apply settings to each PHP version
for php_version in ${INSTALLED_PHP_VERSIONS}; do
    process_step "Configuring $php_version settings"
    
    # Create backup of PHP ini
    php_ini_path=$(/opt/cpanel/${php_version}/root/usr/bin/php -i | grep "Loaded Configuration File" | awk '{print $5}')
    if [ -n "$php_ini_path" ]; then
        backup_file "$php_ini_path"
    fi
    
    for directive in "${PHP_DIRECTIVES[@]}"; do
        whmapi1 php_ini_set_directives directive="$directive" version="$php_version"
    done
    success_msg "$php_version configured with optimized settings"
done

# Set default PHP version (PHP 8.2 if available, otherwise keep current)
CURRENT_DEFAULT_PHP=$(whmapi1 php_get_system_default_version | grep version | awk '{print $2}')
if [[ "$INSTALLED_PHP_VERSIONS" == *"$DEFAULT_PHP"* ]]; then
    process_step "Setting default PHP version to $DEFAULT_PHP"
    whmapi1 php_set_system_default_version version=$DEFAULT_PHP
    success_msg "Default PHP version set to $DEFAULT_PHP"
else
    success_msg "Keeping current default PHP version: $CURRENT_DEFAULT_PHP"
fi

process_step "Setting PHP handlers and restarting services"
whmapi1 php_get_installed_versions | awk '/ea-php/ {print $2}' | xargs -i -n1 whmapi1 php_set_handler version='{}' handler='cgi'
/usr/local/cpanel/scripts/restartsrv_cpsrvd

# Enable PHP-FPM
process_step "Enabling PHP-FPM for all accounts"
whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm='1'
/scripts/restartsrv_apache_php_fpm

# Configure PHP-FPM open_basedir
backup_file "/var/cpanel/ApachePHPFPM/system_pool_defaults.yaml"
printf "php_value_open_basedir: { name: 'php_value[open_basedir]', value: \"[%% documentroot %%]:[%% homedir %%]:/var/cpanel/php/sessions/[%% ea_php_version %%]:/tmp:/var/tmp\" }\n" >> /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml
/scripts/php_fpm_config --rebuild
success_msg "PHP-FPM configured for all accounts"

# Install Memcached if not already installed
section_header "Checking and Configuring Memcached"
if ! rpm -q memcached > /dev/null; then
    process_step "Installing Memcached"
    dnf -y install memcached
    systemctl enable memcached
    success_msg "Memcached installed and enabled"
else
    success_msg "Memcached is already installed"
fi

# Configure Memcached for security
process_step "Securing Memcached"
backup_file "/etc/sysconfig/memcached"
perl -pi -e "s/OPTIONS=\"\"/OPTIONS=\"-l 127.0.0.1 -U 0\"/g" /etc/sysconfig/memcached
systemctl restart memcached
success_msg "Memcached configured for security (localhost only, UDP disabled)"

# Without the PHP extension the daemon is unusable from web apps
process_step "Installing Memcached PHP extensions"
dnf -y install libmemcached-awesome-devel cyrus-sasl-devel zlib-devel 2>/dev/null || dnf -y install libmemcached-devel cyrus-sasl-devel zlib-devel
for php_version in $INSTALLED_PHP_VERSIONS; do
    if /opt/cpanel/${php_version}/root/usr/bin/php -m 2>/dev/null | grep -q '^memcached$'; then
        log "memcached extension already present for $php_version"
    # Prefer cPanel's packaged extension — it survives PHP updates
    elif yum install -y "${php_version}-php-memcached" >/dev/null 2>&1; then
        log "memcached extension (RPM) installed for $php_version"
    else
        printf '\n\n\n\n\n\n\n\n\n\n' | /opt/cpanel/${php_version}/root/usr/bin/pecl install memcached \
            && log "memcached extension (PECL) installed for $php_version" \
            || warning_msg "memcached extension failed for $php_version (continuing)"
    fi
done
success_msg "Memcached PHP extensions processed"

# Install ImageMagick with PHP extensions if not already installed
section_header "Checking and Installing ImageMagick"
if ! rpm -q ImageMagick ImageMagick-devel > /dev/null; then
    process_step "Installing ImageMagick and PHP extensions"
    dnf config-manager --set-enabled epel
    dnf install ImageMagick ImageMagick-devel -y
    success_msg "ImageMagick installed"
else
    success_msg "ImageMagick is already installed"
fi

# Check and install ImageMagick PHP extensions
process_step "Configuring ImageMagick PHP extensions"
for php_version in "${IMAGICK_COMPATIBLE[@]}"; do
    if [[ " ${INSTALLED_PHP_VERSIONS} " == *" ${php_version} "* ]]; then
        # Check if imagick is already installed for this PHP version
        if ! /opt/cpanel/${php_version}/root/usr/bin/php -m | grep -q imagick; then
            process_step "Installing ImageMagick extension for $php_version"
            yes | /opt/cpanel/${php_version}/root/usr/bin/pecl install imagick
            success_msg "ImageMagick extension installed for $php_version"
        else
            success_msg "ImageMagick extension already installed for $php_version"
        fi
    fi
done

/scripts/restartsrv_apache_php_fpm
success_msg "PHP configuration with ImageMagick extensions completed"

# Configure MySQL
section_header "Configuring MySQL"

# Generate a random strong password for MySQL
ROOT_PASS=$(openssl rand -base64 12)
process_step "Setting up MySQL root password"

# Move existing .my.cnf to .my.cnf-bak if already exist
if [ -f ~/.my.cnf ]; then
    backup_file ~/.my.cnf
fi

# Create new .my.cnf with root password
cat > ~/.my.cnf << EOF
[client]
user=root
password=${ROOT_PASS}
EOF

# Change permissions to only allow root to read and write
chmod 600 ~/.my.cnf
success_msg "MySQL client configuration created"

# Backup existing /etc/my.cnf if exists
if [ -f /etc/my.cnf ]; then
    backup_file /etc/my.cnf
fi

# Create optimized my.cnf file (compatible with both MySQL and MariaDB)
# Scale connections to server role
MYSQL_MAX_CONN=$([ "$SERVER_TYPE" == "shared" ] && echo 500 || echo 200)
# Keep a rollback copy of the previous config
[ -f /etc/my.cnf ] && cp -f /etc/my.cnf /etc/my.cnf.pre-easycpanel
cat > /etc/my.cnf << EOF
[mysqld]
# NOTE: socket/pid-file/datadir intentionally NOT overridden —
# cPanel and the OS defaults are correct (mysql.sock); overriding them
# breaks client connections and service detection.

# InnoDB Settings
innodb_buffer_pool_size = ${BPOOL}
innodb_file_per_table   = 1
innodb_flush_log_at_trx_commit = 2
innodb_flush_method     = O_DIRECT
innodb_log_file_size    = 256M
innodb_log_buffer_size  = 16M

# Connection Settings
max_connections         = ${MYSQL_MAX_CONN}
max_allowed_packet      = 256M
wait_timeout            = 300
interactive_timeout     = 300
thread_cache_size       = 16
thread_stack            = 256K

# Table Settings
table_open_cache        = 4000

# MyISAM Settings
key_buffer_size         = 32M
EOF

# Fix MySQL startup by creating mysqld runtime directory

mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld
chmod 755 /var/run/mysqld

# Restart MySQL via cPanel (works for MySQL and MariaDB) and verify it came back
/scripts/restartsrv_mysql
sleep 5
if mysqladmin status >/dev/null 2>&1; then
    success_msg "MySQL optimized with innodb_buffer_pool_size = ${BPOOL}"
else
    error_msg "MySQL failed to restart with the new config — rolling back"
    [ -f /etc/my.cnf.pre-easycpanel ] && cp -f /etc/my.cnf.pre-easycpanel /etc/my.cnf
    /scripts/restartsrv_mysql
    warning_msg "Previous MySQL config restored; review /etc/my.cnf manually"
fi

# Check if CSF Firewall is installed, install if not
section_header "Checking and Configuring CSF Firewall"
if [ ! -d "/etc/csf" ]; then
    process_step "CSF Firewall not found, installing"
    cd /usr/src || exit 1
    rm -fv csf.tgz
    # Download from the project mirror with checksum verification — if the
    # mirror is unreachable/broken or the file is tampered, ABORT rather
    # than continue without a firewall
    if ! download_verified csf.tgz "$EASYCPANEL_CSF_SHA256"; then
        error_msg "Firewall NOT installed — fix the mirror and re-run this section."
        exit 1
    fi
    if ! tar -xzf csf.tgz 2>/dev/null; then
        error_msg "CSF download from script.ahtshamjutt.com failed or is corrupt."
        error_msg "Firewall NOT installed — fix the mirror and re-run this section."
        exit 1
    fi
    cd csf || exit 1
    sh install.sh
    success_msg "CSF Firewall installed"
else
    success_msg "CSF Firewall already installed"
fi

# Configure CSF
process_step "Configuring CSF Firewall"
backup_file "/etc/csf/csf.conf"

sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
log "Set CSF to live mode by disabling testing"

sed -i 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "2"/g' /etc/csf/csf.conf
log "Restricted syslog/rsyslog access"

sed -i 's/MESSENGER = "0"/MESSENGER = "1"/g' /etc/csf/csf.conf
log "Enabled CSF Messenger service"

# Update CSF ports - add new SSH port if changed
if [ "$CHANGE_SSH_PORT" = true ]; then
    process_step "Updating firewall for new SSH port $SSH_PORT"
    # Update TCP_IN ports to include new SSH port
    CURRENT_TCP_IN=$(grep ^TCP_IN /etc/csf/csf.conf | cut -d'"' -f2)
    NEW_TCP_IN=$(echo $CURRENT_TCP_IN | sed "s/,${CURRENT_SSH_PORT},/,${SSH_PORT},/")
    sed -i "s/^TCP_IN = \"$CURRENT_TCP_IN\"/TCP_IN = \"$NEW_TCP_IN\"/g" /etc/csf/csf.conf
    
    # Also update sshd_config
    backup_file "/etc/ssh/sshd_config"
    sed -i "s/^Port ${CURRENT_SSH_PORT}/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    # If the port is commented out, uncomment it
    sed -i "s/^#Port ${CURRENT_SSH_PORT}/Port ${SSH_PORT}/g" /etc/ssh/sshd_config
    log "SSH port changed from $CURRENT_SSH_PORT to $SSH_PORT in sshd_config"
else
    log "Keeping current SSH port: $SSH_PORT"
    # Ensure the current SSH port is in the CSF configuration
    CURRENT_TCP_IN=$(grep ^TCP_IN /etc/csf/csf.conf | cut -d'"' -f2)
    if [[ ! "$CURRENT_TCP_IN" =~ ,$SSH_PORT, ]]; then
        warning_msg "Adding current SSH port $SSH_PORT to CSF firewall rules"
        NEW_TCP_IN=$(echo $CURRENT_TCP_IN | sed "s/,22,/,22,${SSH_PORT},/")
        sed -i "s/^TCP_IN = \"$CURRENT_TCP_IN\"/TCP_IN = \"$NEW_TCP_IN\"/g" /etc/csf/csf.conf
    fi
fi

# Configure CSF Firewall settings
sed -i 's/TCP_OUT = ".*"/TCP_OUT = "20,21,22,25,43,53,80,113,443,587,873,2087,2089,2200,2703"/g' /etc/csf/csf.conf
sed -i 's/UDP_IN = ".*"/UDP_IN = "20,21,53"/g' /etc/csf/csf.conf
sed -i 's/UDP_OUT = ".*"/UDP_OUT = "20,21,53,113,123,873,6277"/g' /etc/csf/csf.conf
sed -i 's/ICMP_IN_RATE = ".*"/ICMP_IN_RATE = "50\/s"/g' /etc/csf/csf.conf
sed -i 's/USE_CONNTRACK = ".*"/USE_CONNTRACK = "0"/g' /etc/csf/csf.conf
sed -i 's/SYSLOG_CHECK = ".*"/SYSLOG_CHECK = "3600"/g' /etc/csf/csf.conf
sed -i 's/RELAYHOSTS = ".*"/RELAYHOSTS = "1"/g' /etc/csf/csf.conf
sed -i 's/VERBOSE = ".*"/VERBOSE = "0"/g' /etc/csf/csf.conf
sed -i 's/DROP_NOLOG = ".*"/DROP_NOLOG = "67,68,111,113,135:139,445,500,513,520,585"/g' /etc/csf/csf.conf
sed -i 's/LF_PERMBLOCK_ALERT = ".*"/LF_PERMBLOCK_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_NETBLOCK_ALERT = ".*"/LF_NETBLOCK_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/CC_INTERVAL = ".*"/CC_INTERVAL = "7"/g' /etc/csf/csf.conf
sed -i 's/LF_EMAIL_ALERT = ".*"/LF_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf
sed -i 's/SAFECHAINUPDATE = "0"/SAFECHAINUPDATE = "1"/g' /etc/csf/csf.conf
sed -i 's/LF_SSHD_PERM = "1"/LF_SSHD_PERM = "3600"/g' /etc/csf/csf.conf
sed -i 's/LF_FTPD_PERM = "1"/LF_FTPD_PERM = "3600"/g' /etc/csf/csf.conf
sed -i 's/LF_CPANEL_PERM ="1"/LF_CPANEL_PERM = "1800"/g' /etc/csf/csf.conf
sed -i 's/LF_SMTPAUTH_PERM = "1"/LF_SMTPAUTH_PERM = "1800"/g' /etc/csf/csf.conf
sed -i 's/LF_POP3D_PERM = "1"/LF_POP3D_PERM = "1800"/g' /etc/csf/csf.conf
sed -i 's/LF_IMAPD_PERM = "1"/LF_IMAPD_PERM = "1800"/g' /etc/csf/csf.conf
sed -i 's/LF_HTACCESS_PERM = "1"/LF_HTACCESS_PERM = "1800"/g' /etc/csf/csf.conf
sed -i 's/LF_MODSEC_PERM = "1"/LF_MODSEC_PERM = "1800"/g' /etc/csf/csf.conf

# Add protections against SYN and flood attacks
process_step "Configuring CSF protection against SYN floods and DDoS attacks"

# Enable SYN flood protection with balanced settings
sed -i 's/SYNFLOOD = "0"/SYNFLOOD = "1"/g' /etc/csf/csf.conf
sed -i 's/SYNFLOOD_RATE = ".*"/SYNFLOOD_RATE = "300\/s"/g' /etc/csf/csf.conf
sed -i 's/SYNFLOOD_BURST = ".*"/SYNFLOOD_BURST = "500"/g' /etc/csf/csf.conf

# Set connection tracking limit
sed -i 's/CT_LIMIT = ".*"/CT_LIMIT = "500"/g' /etc/csf/csf.conf

# Configure port flood protection - balanced for high traffic sites
# Format: "port;protocol;connections_per_second;seconds"
sed -i 's/PORTFLOOD = ".*"/PORTFLOOD = "80;tcp;100\/s;20,443;tcp;100\/s;20"/g' /etc/csf/csf.conf

# Configure connection limits - allow more connections for web ports
# Format: "port;max_connections"
sed -i 's/CONNLIMIT = ".*"/CONNLIMIT = "22;10,80;400,443;400"/g' /etc/csf/csf.conf

# Enable packet filtering for additional protection
sed -i 's/PACKET_FILTER = ".*"/PACKET_FILTER = "1"/g' /etc/csf/csf.conf

# Kernel network & memory tuning: connection queues, swappiness, BBR
# congestion control and transparent hugepages (see lib.sh)
apply_kernel_tuning

# Add comment to CSF configuration file about adjusting these values
echo "# Note: The DDoS protection values are set to balanced defaults." >> /etc/csf/csf.conf
echo "# If you experience false positives or need to accommodate higher traffic," >> /etc/csf/csf.conf
echo "# you may need to increase SYNFLOOD_RATE, SYNFLOOD_BURST, PORTFLOOD and CONNLIMIT values." >> /etc/csf/csf.conf

# Enable DYNDNS to block abuse from dynamic DNS providers
sed -i 's/DYNDNS = ".*"/DYNDNS = "300"/g' /etc/csf/csf.conf

log "Configured balanced DDoS protection settings for high-traffic websites"

# Restart CSF and SSH if port changed
csf -r
if [ "$CHANGE_SSH_PORT" = true ]; then
    process_step "Restarting SSH with new port configuration"
    systemctl restart sshd
    warning_msg "SSH port has been changed to $SSH_PORT. Please use this port for future connections."
else
    systemctl restart sshd
fi
success_msg "CSF Firewall configured with DDoS protection"

# Enable symlink protection
section_header "Enabling Security Features"
process_step "Enabling Symlink Protection"
backup_file "/etc/apache2/conf/httpd.conf"
sed -i 's/SymlinkProtect Off/SymlinkProtect On/' /etc/apache2/conf/httpd.conf
/scripts/rebuildhttpdconf
/scripts/restartsrv_httpd
success_msg "Symlink protection enabled"

# Install ModSecurity OWASP ruleset if not already installed
process_step "Checking ModSecurity OWASP ruleset"
if ! rpm -q ea-modsec2-rules-owasp-crs > /dev/null; then
    process_step "Installing ModSecurity OWASP ruleset"
    yes | yum install ea-modsec2-rules-owasp-crs -y
    success_msg "ModSecurity OWASP ruleset installed"
else
    success_msg "ModSecurity OWASP ruleset already installed"
fi

# Check and install ImunifyAV if not already installed
section_header "Checking and Installing ImunifyAV"
if ! rpm -q imunify-antivirus > /dev/null; then
    process_step "Downloading and installing ImunifyAV"
    cd /root/ || exit 1
    wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh
    bash imav-deploy.sh
    sed -i -e "s|cpu: .*|cpu: 1|" -e "s|io: .*|io: 1|" /etc/sysconfig/imunify360/imunify360.config
    systemctl restart imunify-antivirus
    /usr/share/av-userside-plugin.sh
    success_msg "ImunifyAV installed and configured"
else
    process_step "ImunifyAV already installed, optimizing configuration"
    sed -i -e "s|cpu: .*|cpu: 1|" -e "s|io: .*|io: 1|" /etc/sysconfig/imunify360/imunify360.config
    systemctl restart imunify-antivirus
    success_msg "ImunifyAV configuration optimized"
fi

# Additional security configurations
section_header "Additional Security Configurations"
process_step "Disabling compilers"
/scripts/compilers off
success_msg "Compilers disabled"

process_step "Disabling SMTP mail restrictions"
/scripts/smtpmailgidonly off
success_msg "SMTP mail restrictions disabled"

process_step "Enabling shell fork bomb protection"
perl -I/usr/local/cpanel -MCpanel::LoginProfile -le 'print [Cpanel::LoginProfile::install_profile("limits")]->[1];'
success_msg "Shell fork bomb protection enabled"

process_step "Disabling rpcbind service"
systemctl stop rpcbind
systemctl disable rpcbind
success_msg "rpcbind service disabled"

# Disable cPHulk to avoid false positives
section_header "Disabling cPHulk (Brute Force Protection)"
process_step "Disabling cPHulk to prevent false positives"
whmapi1 configureservice service=cphulkd enabled=0 monitored=0
/usr/local/cpanel/etc/init/stopcphulkd
/usr/local/cpanel/bin/cphulk_pam_ctl --disable
success_msg "cPHulk service disabled"

# Configure background process killer
process_step "Configuring background process killer"
whmapi1 configurebackgroundprocesskiller processes_to_kill='BitchX' processes_to_kill-1='bnc' processes_to_kill-2='eggdrop' processes_to_kill-3='generic-sniffers' processes_to_kill-4='guardservices' processes_to_kill-5='ircd' processes_to_kill-6='psyBNC' processes_to_kill-7='ptlink' processes_to_kill-8='services'
systemctl restart cpanel
success_msg "Background process killer configured"

# Enable service monitoring
section_header "Enabling Service Monitoring"
process_step "Enabling monitoring for all services"
whmapi1 enable_monitor_all_enabled_services
success_msg "Service monitoring enabled"

# Configure tweak settings
section_header "Configuring Tweak Settings"
process_step "Updating cPanel tweak settings"
show_progress

whmapi1 set_tweaksetting key=phploader value=sourceguardian,ioncube
log "Enabled SourceGuardian and IonCube loaders"

whmapi1 set_tweaksetting key=php_upload_max_filesize value=512
log "Set PHP upload max filesize to 512MB"

whmapi1 set_tweaksetting key=skipboxtrapper value=1
log "Disabled BoxTrapper spam trap"

whmapi1 set_tweaksetting key=resetpass value=0
log "Disabled password reset for cPanel accounts"

whmapi1 set_tweaksetting key=resetpass_sub value=0
log "Disabled Subaccount password reset"

whmapi1 set_tweaksetting key=referrerblanksafety value=1
log "Enabled blank referrer safety check"

whmapi1 set_tweaksetting key=referrersafety value=1
log "Enabled referrer safety check"

whmapi1 set_tweaksetting key=cgihidepass value=1
log "Enabled CGI script password hiding in logs"

whmapi1 set_tweaksetting key=maxemailsperhour value=200
log "Set maximum number of emails per hour to 200"

success_msg "Tweak settings configured for server security"
# Check and Install Redis
section_header "Checking and Installing Redis"
if ! rpm -q redis > /dev/null; then
    process_step "Installing Redis"
        dnf -y install redis
    systemctl enable redis
    systemctl start redis
    success_msg "Redis service installed and started"
else
    success_msg "Redis is already installed"
    systemctl enable redis
    systemctl restart redis
fi

# Harden Redis on shared servers — without a password any local account can
# read or flush the cache of every other account
if [[ "$SERVER_TYPE" == "shared" ]]; then
    REDIS_CONF=$([ -f /etc/redis/redis.conf ] && echo /etc/redis/redis.conf || echo /etc/redis.conf)
    if [ -f "$REDIS_CONF" ] && ! grep -q '^requirepass' "$REDIS_CONF"; then
        REDIS_PASS=$(openssl rand -hex 16)
        echo "requirepass $REDIS_PASS" >> "$REDIS_CONF"
        echo "$REDIS_PASS" > /root/.redis.pass && chmod 600 /root/.redis.pass
        systemctl restart redis
        success_msg "Redis password enabled (stored in /root/.redis.pass)"
    fi
fi
process_step "Installing Redis PHP extensions"
for php_version in ${INSTALLED_PHP_VERSIONS}; do
    # Check if Redis extension is already installed
    if ! /opt/cpanel/${php_version}/root/usr/bin/php -m | grep -q redis; then
        process_step "Installing Redis extension for $php_version"
        yes "no" | /opt/cpanel/${php_version}/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis
        success_msg "Redis extension installed for $php_version"
    else
        success_msg "Redis extension already installed for $php_version"
    fi
done

success_msg "Redis PHP extensions installed or verified"

# PHP performance tuning and system hardening
section_header "PHP Performance Tuning & System Hardening"
tune_php_opcache
tune_php_fpm_pools
secure_tmp
secure_cache_daemons

# Setup login info script
process_step "Setting up login information script"
backup_file "/etc/ssh/sshd_config"
perl -pi -e "s/#PrintMotd yes/PrintMotd no/g" /etc/ssh/sshd_config
systemctl restart sshd

# Copy the login-info.sh from script directory to profile.d
if [ -f "$SCRIPT_DIR/login-info.sh" ]; then
    cp "$SCRIPT_DIR/login-info.sh" /etc/profile.d/
    chmod +x /etc/profile.d/login-info.sh
    success_msg "Copied login-info.sh to /etc/profile.d/ and set execute permission"
else
    error_msg "login-info.sh not found in script directory: $SCRIPT_DIR"
    log "Listing files in script directory:"
    ls -la "$SCRIPT_DIR" >> "${LOG_FILE}"
    exit 1
fi

# Cleanup
section_header "Cleanup"
process_step "Cleaning up temporary files"
rm -rf /usr/src/csf.tgz
rm -rf /root/imav-deploy.sh
success_msg "Cleanup completed"

# Final banner with server information
clear
btop "$BLUE"
bctr "$BLUE" "${GREEN}OPTIMIZATION COMPLETE"
bsep "$BLUE"
brow "$BLUE" ""
brow "$BLUE" " ${WHITE}Your cPanel server has been successfully optimized and secured."
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Server Information:"
brow "$BLUE" " ${GREEN}• IP Address:${NC} $SERVER_IP"
brow "$BLUE" " ${GREEN}• SSH Port:${NC} $SSH_PORT"
brow "$BLUE" " ${GREEN}• Hostname:${NC} $HOSTNAME"
brow "$BLUE" " ${GREEN}• Server Type:${NC} $([ "$SERVER_TYPE" == "personal" ] && echo "Personal" || echo "Shared Hosting")"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Apache Configuration:"
brow "$BLUE" " ${GREEN}• MaxRequestWorkers:${NC} $FINAL_MRW"
brow "$BLUE" " ${GREEN}• MySQL Buffer Pool:${NC} $BPOOL"
brow "$BLUE" ""

# Add resource allocation disclaimer for Personal servers
if [[ "$SERVER_TYPE" == "personal" ]]; then
    brow "$BLUE" " ${YELLOW}Resource Allocation:"
    brow "$BLUE" " ${WHITE}• Apache and MySQL configurations are optimized based on a resource"
    brow "$BLUE" " ${WHITE}  allocation ratio of 35% Apache, 30% MySQL, and 35% for the OS."
    brow "$BLUE" " ${WHITE}• These settings are automatically tuned to your server's resources"
    brow "$BLUE" " ${WHITE}  and can be further optimized based on traffic patterns and volume."
    brow "$BLUE" ""
fi

brow "$BLUE" " ${YELLOW}Access Information:"
brow "$BLUE" " ${GREEN}• WHM URL:${NC} https://$SERVER_IP:2087"
brow "$BLUE" " ${GREEN}• cPanel URL:${NC} https://$SERVER_IP:2083"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Security Features:"
brow "$BLUE" " ${GREEN}• CSF Firewall:${NC} Enabled with DDoS protection"
brow "$BLUE" " ${GREEN}• ModSecurity:${NC} Enabled with OWASP ruleset"
brow "$BLUE" " ${GREEN}• ImunifyAV:${NC} Installed and configured"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Backup Information:"
brow "$BLUE" " ${GREEN}• All original configurations backed up to:${NC}"
brow "$BLUE" "   ${WHITE}$BACKUP_DIR${NC}"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}IMPORTANT:${NC}"
brow "$BLUE" " ${WHITE}• MySQL Root Password has been set and saved in /root/.my.cnf"
brow "$BLUE" " ${WHITE}• All details are logged in ${GREEN}$LOG_FILE"
brow "$BLUE" ""
bsep "$BLUE"
brow "$BLUE" ""
brow "$BLUE" " ${CYAN}If you found this script helpful, please consider supporting:"
brow "$BLUE" " ${WHITE}☕ https://ko-fi.com/ahtshamjutt"
brow "$BLUE" ""
bbot "$BLUE"
echo ""
echo -e "${YELLOW}A system reboot is recommended to complete the optimization.${NC}"
echo -e "${GREEN}Please run 'reboot' when convenient.${NC}"
echo ""

# Warning about SSH port if it was changed
if [ "$CHANGE_SSH_PORT" = true ]; then
    btop "$RED"
    bctr "$RED" "IMPORTANT NOTICE"
    bsep "$RED"
    brow "$RED" "${YELLOW} Your SSH port has been changed to: ${WHITE}$SSH_PORT"
    brow "$RED" "${YELLOW} You will need to use this port for future SSH connections"
    bbot "$RED"
    echo ""
fi

# Log final information
log "Optimization completed successfully!"
log "Server IP: $SERVER_IP"
log "SSH Port: $SSH_PORT" 
log "Server Type: $SERVER_TYPE"
log "Apache MaxRequestWorkers: $FINAL_MRW"
log "MySQL Buffer Pool: $BPOOL"
log "Backup Directory: $BACKUP_DIR"
log "Optimization completed at $(date)"
