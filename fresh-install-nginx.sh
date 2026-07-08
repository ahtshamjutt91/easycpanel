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

# Initialize installation flag (used to control screen clearing)
INSTALLATION_STARTED="no"

# Define the log file location
LOG_FILE="/root/panelbot-serversetup.log"

# Check for Root Privileges
require_root

# Clear the screen for a clean look
clear

# Display a compact banner
btop "$BLUE"
bctr "$BLUE" "${GREEN}cPanel Configuration, Hardening & Security"
bctr "$BLUE" "${YELLOW}Created by Ahtsham Jutt"
bctr "$BLUE" "${WHITE}Website: ahtshamjutt.com | me@ahtshamjutt.com"
bctr "$BLUE" "${CYAN}Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕"
bbot "$BLUE"

# Display installation time notice
echo; btop "$YELLOW"
bctr "$YELLOW" "${WHITE}IMPORTANT NOTICE"
bsep "$YELLOW"
brow "$YELLOW" "${WHITE} • The total installation time depends on your server's:"
brow "$YELLOW" "${WHITE}   - CPU performance"
brow "$YELLOW" "${WHITE}   - Disk I/O speed"
brow "$YELLOW" "${WHITE}   - Network connection"
brow "$YELLOW" ""
brow "$YELLOW" "${WHITE} • cPanel installation alone can take 30-60 minutes"
brow "$YELLOW" "${WHITE} • Full script completion may take 1-2 hours"
brow "$YELLOW" ""
brow "$YELLOW" "${WHITE} • Please be patient - this is not related to script efficiency"
brow "$YELLOW" "${WHITE}   but depends on server resources and internet speed"
bbot "$YELLOW"
sleep 5

# Detect OS and set PHP versions
section_header "Detecting Operating System"
detect_os

# Collect information
section_header "Required Information"

btop "$CYAN"
brow "$CYAN" "${WHITE} Please provide your domain/website URL (e.g., example.com):"
bbot "$CYAN"
while true; do
    read -rp "▶ " domain
    domain=${domain#http://}; domain=${domain#https://}; domain=${domain%%/*}
    [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$ ]] && break
    echo -e "${RED}✗${NC} Invalid domain. Enter a bare domain like ${GREEN}example.com${NC}"
done
log "Domain set to: $domain"

echo; btop "$CYAN"
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

echo; btop "$CYAN"
brow "$CYAN" "${WHITE} SSH Port Configuration:"
bsep "$CYAN"
brow "$CYAN" "${YELLOW} WARNING: Using default port 22 is NOT recommended for security"
brow "$CYAN" "${YELLOW} reasons. It's a primary target for brute force attacks."
bbot "$CYAN"
echo -e "${WHITE}Choose your SSH port configuration:${NC}"
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
log "SSH port set to: $SSH_PORT"

# Fetch server's main IP address
section_header "Fetching Server Information"
process_step "Detecting server's main IP address"
SERVER_IP=$(hostname -I | awk '{print $1}')
success_msg "Server IP detected: $SERVER_IP"

# Display information summary and proceed
echo; btop "$CYAN"
brow "$CYAN" "${WHITE} Installation will proceed with the following settings:"
bsep "$CYAN"
brow "$CYAN" "${WHITE} Domain: ${GREEN}$domain"
brow "$CYAN" "${WHITE} Email: ${GREEN}$email"
brow "$CYAN" "${WHITE} Server IP: ${GREEN}$SERVER_IP"
brow "$CYAN" "${WHITE} SSH Port: ${GREEN}$SSH_PORT"
brow "$CYAN" "${WHITE} Server Type: ${GREEN}$([ "$SERVER_TYPE" == "personal" ] && echo "Personal" || echo "Shared Hosting")"
bbot "$CYAN"

log "Installation will proceed with: Domain=$domain, Email=$email, IP=$SERVER_IP, SSH Port=$SSH_PORT, Type=$SERVER_TYPE"
sleep 4

# Main installation begins
# Now we can start clearing the screen for new sections
INSTALLATION_STARTED="yes"
clear
section_header "Starting cPanel Installation and Configuration"
warning_msg "This process will take some time. Please be patient."

# Update system packages
section_header "Updating System Packages"
process_step "Running system update"
sudo dnf update -y
success_msg "System update completed"

process_step "Installing wget and nano"
sudo dnf install wget nano -y
success_msg "Wget and nano text editor installed"

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

process_step "Disabling SELinux"
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
success_msg "SELinux disabled"

# Install cPanel
section_header "Installing cPanel/WHM"
process_step "Downloading and running cPanel installer"
cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest
success_msg "cPanel installation completed"

section_header "Configuring Network Interface"
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

# Configure basic cPanel settings
section_header "Configuring cPanel Basic Settings"
process_step "Setting up basic cPanel configuration"
sudo touch /etc/.whostmgrft
sudo mv /etc/wwwacct.conf /etc/wwwacct.conf.bk
cat > /etc/wwwacct.conf << EOF
ADDR $SERVER_IP
CONTACTEMAIL $email
CONTACTPAGER
DEFMOD jupiter
ETHDEV $INTERFACE
HOMEDIR /home
HOMEMATCH home
HOST server.$domain
LOGSTYLE combined
MINUID
NS ns1.$domain
NS2 ns2.$domain
NS3
NS4
NSTTL 86400
SCRIPTALIAS y
TTL 14400
EOF
success_msg "Basic cPanel configuration completed"

# Set hostname
section_header "Setting Server Hostname"
process_step "Configuring server hostname to server.$domain"
hostnamectl set-hostname server.$domain
/usr/local/cpanel/bin/set_hostname server.$domain
/scripts/restartsrv_cpsrvd
/scripts/restartsrv_httpd
success_msg "Hostname set to server.$domain"
warning_msg "Make sure to add A record for server.$domain with IP $SERVER_IP"

# Initialize disk quotas
section_header "Enabling Disk Quotas"
process_step "Initializing disk quotas"
yes | /scripts/initquotas
success_msg "Disk quotas enabled"

# Auto-tune Apache and MySQL
section_header "Auto-tuning Apache and MySQL"
process_step "Detecting system resources for optimization"

# 1. Detect Total System RAM (MB)
TOTAL_MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
log "Total RAM detected: ${TOTAL_MEM_MB} MB"

# 2. Set resource allocation ratios
# Adjusted for Nginx+Apache setup (less memory for Apache since Nginx handles most requests)
APACHE_RATIO=0.25  # Less than Apache-only setup (was 0.35)
MYSQL_RATIO=0.30
NGINX_RATIO=0.10   # Add memory allocation for Nginx

# 3. Calculate memory allocations
APACHE_MB=$(awk -v mem="$TOTAL_MEM_MB" -v r="$APACHE_RATIO" 'BEGIN{printf "%d", mem*r}')
MYSQL_MB=$(awk -v mem="$TOTAL_MEM_MB" -v r="$MYSQL_RATIO" 'BEGIN{printf "%d", mem*r}')
NGINX_MB=$(awk -v mem="$TOTAL_MEM_MB" -v r="$NGINX_RATIO" 'BEGIN{printf "%d", mem*r}')

log "Allocating $NGINX_MB MB to Nginx, $APACHE_MB MB to Apache/PHP-FPM, $MYSQL_MB MB to MySQL, rest for OS."

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
    
    # Lower concurrency cap for Nginx-fronted setup
    MAX_CONCURRENCY_CAP=1000
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
        
        # Cap at 16 child processes (concurrency up to 1024)
        MAX_SERVERLIMIT=16
        if [ "$SERVER_LIMIT" -gt "$MAX_SERVERLIMIT" ]; then
            SERVER_LIMIT=$MAX_SERVERLIMIT
        fi
        
        FINAL_MRW=$(( SERVER_LIMIT * 64 ))
    fi
    
    log "Dynamic Apache configuration: ThreadsPerChild=$THREADS_PER_CHILD, ServerLimit=$SERVER_LIMIT, MaxRequestWorkers=$FINAL_MRW"
else
    # Static configuration for shared hosting
    process_step "Using static Apache tuning for shared hosting server"
    
    # Lower values for Nginx-fronted setup
    SERVER_LIMIT=8
    THREADS_PER_CHILD=25
    FINAL_MRW=200
    
    log "Static Apache configuration: ThreadsPerChild=$THREADS_PER_CHILD, ServerLimit=$SERVER_LIMIT, MaxRequestWorkers=$FINAL_MRW"
fi

# Create Apache configuration (reduced values for Nginx-fronted setup)
cat <<EOL > /etc/apache2/conf.d/includes/pre_main_global.conf
<IfModule event.c>
    ServerLimit              $SERVER_LIMIT
    StartServers             2
    MinSpareThreads          25
    MaxSpareThreads          75
    ThreadsPerChild          $THREADS_PER_CHILD
    MaxRequestWorkers        $FINAL_MRW
    MaxConnectionsPerChild   0
</IfModule>
EOL

# Update EA4 YAML configuration
sed -i \
  -e "s/\(maxclients[\" ]*:\)\s[0-9\"]\+/\1 $FINAL_MRW/" \
  -e 's/\(maxrequestsperchild[" ]*:\)\s[0-9"]\+/\1 0/' \
  -e "s/\(serverlimit[\" ]*:\)\s[0-9\"]\+/\1 $SERVER_LIMIT/" \
  -e 's/\(startservers[" ]*:\)\s[0-9"]\+/\1 2/' \
  -e "s/\(threadsperchild[\" ]*:\)\s[0-9\"]\+/\1 $THREADS_PER_CHILD/" \
  -e 's/\(symlink_protect[" ]*:\)\s[A-Za-z0-9"]\+/\1 "On"/' \
  /etc/cpanel/ea4/ea4.conf

/scripts/rebuildhttpdconf
/scripts/restartsrv_httpd
success_msg "Apache configured with MaxRequestWorkers = $FINAL_MRW"

# 5. Configure MySQL
section_header "Configuring MySQL"

# Generate a random strong password for MySQL
ROOT_PASS=$(openssl rand -base64 12)
process_step "Setting up MySQL root password"

# Move existing .my.cnf to .my.cnf-bak if already exist
if [ -f ~/.my.cnf ]; then
    mv ~/.my.cnf ~/.my.cnf-bak
    log "Backed up existing ~/.my.cnf file"
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
    mv /etc/my.cnf /etc/my.cnf-bak
    log "Backed up existing /etc/my.cnf file"
fi

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

# Configure EasyApache4
section_header "Configuring EasyApache4"
process_step "Installing PHP versions, extensions and Apache modules"

# Create directory for custom profiles if it doesn't exist
mkdir -p /etc/cpanel/ea4/profiles/custom/

# Select the appropriate EasyApache profile based on OS version
if [[ "$MAJOR_VERSION" == "8" ]]; then
    EA4_PROFILE="event-php-fpm-almalinux8.json"
    log "Using EasyApache profile for AlmaLinux/CloudLinux 8"
else
    EA4_PROFILE="event-php-fpm-almalinux9.json"
    log "Using EasyApache profile for AlmaLinux/CloudLinux 9"
fi

# Copy the profile from script directory to cPanel profiles directory
if [ -f "$SCRIPT_DIR/$EA4_PROFILE" ]; then
    cp "$SCRIPT_DIR/$EA4_PROFILE" "/etc/cpanel/ea4/profiles/custom/"
    success_msg "Found and copied EasyApache profile: $EA4_PROFILE"
else
    error_msg "EasyApache profile $EA4_PROFILE not found in script directory: $SCRIPT_DIR"
    log "Listing files in script directory:"
    ls -la "$SCRIPT_DIR" >> "${LOG_FILE}"
    exit 1
fi

# Install the EasyApache profile
process_step "Installing EasyApache profile (this will take several minutes)"
show_progress
yes | /usr/local/bin/ea_install_profile --install "/etc/cpanel/ea4/profiles/custom/$EA4_PROFILE"
success_msg "EasyApache4 profile installed with PHP versions for $OS_NAME $MAJOR_VERSION"

# Set default PHP version (PHP 8.2 for all OS versions)
process_step "Setting default PHP version to $DEFAULT_PHP"
whmapi1 php_set_system_default_version version="$DEFAULT_PHP"
whmapi1 php_get_installed_versions | awk '/ea-php/ {print $2}' | xargs -i -n1 whmapi1 php_set_handler version='{}' handler='cgi'
/usr/local/cpanel/scripts/restartsrv_cpsrvd
success_msg "Default PHP version set to $DEFAULT_PHP"

# Configure PHP settings
section_header "Configuring PHP Settings"

# Define PHP directives to set
PHP_DIRECTIVES=(
    "memory_limit:256M"
    "post_max_size:512M"
    "upload_max_filesize:512M"
    "max_input_vars:10000"
)

# Apply settings to each PHP version
for php_version in "${PHP_VERSIONS[@]}"; do
    process_step "Configuring $php_version settings"
    for directive in "${PHP_DIRECTIVES[@]}"; do
        whmapi1 php_ini_set_directives directive="$directive" version="$php_version"
    done
    success_msg "$php_version configured with optimized settings"
done

# Enable PHP-FPM
process_step "Enabling PHP-FPM for all accounts"
whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm='1'
/scripts/restartsrv_apache_php_fpm

# Configure PHP-FPM open_basedir
printf "php_value_open_basedir: { name: 'php_value[open_basedir]', value: \"[%% documentroot %%]:[%% homedir %%]:/var/cpanel/php/sessions/[%% ea_php_version %%]:/tmp:/var/tmp\" }\n" >> /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml
/scripts/php_fpm_config --rebuild
success_msg "PHP-FPM configured for all accounts"

# Install Memcached
section_header "Installing and Configuring Memcached"
process_step "Installing Memcached"
dnf -y install memcached
systemctl enable memcached
perl -pi -e "s/OPTIONS=\"\"/OPTIONS=\"-l 127.0.0.1 -U 0\"/g" /etc/sysconfig/memcached
systemctl restart memcached
success_msg "Memcached daemon installed and secured (localhost only, UDP off)"

# Without the PHP extension the daemon is unusable from web apps
process_step "Installing Memcached PHP extensions"
dnf -y install libmemcached-awesome-devel cyrus-sasl-devel zlib-devel 2>/dev/null || dnf -y install libmemcached-devel cyrus-sasl-devel zlib-devel
for php_version in "${PHP_VERSIONS[@]}"; do
    printf '\n\n\n\n\n\n\n\n\n\n' | /opt/cpanel/${php_version}/root/usr/bin/pecl install memcached \
        && log "memcached extension installed for $php_version" \
        || warning_msg "memcached extension failed for $php_version (continuing)"
done
success_msg "Memcached PHP extensions processed"

# Install ImageMagick with PHP extensions
section_header "Installing ImageMagick"
process_step "Installing ImageMagick and PHP extensions"
dnf config-manager --set-enabled epel
dnf install ImageMagick ImageMagick-devel -y

for php_version in "${IMAGICK_COMPATIBLE[@]}"; do
    if [[ " ${PHP_VERSIONS[*]} " == *" ${php_version} "* ]]; then
        process_step "Installing ImageMagick extension for $php_version"
        yes | /opt/cpanel/${php_version}/root/usr/bin/pecl install imagick
    fi
done

/scripts/restartsrv_apache_php_fpm
success_msg "ImageMagick installed with PHP extensions"

# Install CSF Firewall
section_header "Installing and Configuring CSF Firewall"
process_step "Downloading and installing CSF Firewall"
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

# Configure CSF
process_step "Configuring CSF Firewall"
sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
log "Set CSF to live mode by disabling testing"

sed -i 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "2"/g' /etc/csf/csf.conf
log "Restricted syslog/rsyslog access"

sed -i 's/MESSENGER = "0"/MESSENGER = "1"/g' /etc/csf/csf.conf
log "Enabled CSF Messenger service"

# Update CSF ports - add new SSH port if changed
if [ "$SSH_PORT" != "22" ]; then
    process_step "Updating firewall for custom SSH port $SSH_PORT"
    # Update TCP_IN ports to include new SSH port
    CURRENT_TCP_IN=$(grep ^TCP_IN /etc/csf/csf.conf | cut -d'"' -f2)
    NEW_TCP_IN=$(echo "$CURRENT_TCP_IN" | sed -E "s/(^|,)22(,|$)/\1$SSH_PORT\2/")
    sed -i "s/^TCP_IN = \"$CURRENT_TCP_IN\"/TCP_IN = \"$NEW_TCP_IN\"/g" /etc/csf/csf.conf
    
    # Also update sshd_config
    sed -i -E "s/^#?Port [0-9]+/Port $SSH_PORT/" /etc/ssh/sshd_config
    log "SSH port changed from 22 to $SSH_PORT in sshd_config"
else
    log "Keeping default SSH port 22"
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

# Restart CSF and SSH
csf -r
systemctl restart sshd
success_msg "CSF Firewall installed and configured with DDoS protection"

if [ "$SSH_PORT" != "22" ]; then
    warning_msg "SSH port has been changed to $SSH_PORT. Please use this port for future connections."
fi

# Install LetsEncrypt SSL plugin
section_header "Installing LetsEncrypt SSL Plugin"
process_step "Installing LetsEncrypt SSL for cPanel"
/usr/local/cpanel/scripts/install_lets_encrypt_autossl_provider
success_msg "LetsEncrypt SSL plugin installed"

process_step "Setting LetsEncrypt as default SSL provider"
whmapi1 set_autossl_provider provider=LetsEncrypt x_terms_of_service_accepted https://letsencrypt.org/documents/LE-SA-v1.3-September-21-2022.pdf
success_msg "LetsEncrypt set as default SSL provider"

# Enable symlink protection
section_header "Enabling Security Features"
process_step "Enabling Symlink Protection"
sed -i 's/SymlinkProtect Off/SymlinkProtect On/' /etc/apache2/conf/httpd.conf && /scripts/rebuildhttpdconf && /scripts/restartsrv_httpd
success_msg "Symlink protection enabled"

# Install ModSecurity OWASP ruleset
process_step "Installing ModSecurity OWASP ruleset"
yes | yum install ea-modsec2-rules-owasp-crs -y
success_msg "ModSecurity OWASP ruleset installed"

# Install ImunifyAV
section_header "Installing ImunifyAV"
process_step "Downloading and installing ImunifyAV"
cd /root/ || exit 1
wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh
bash imav-deploy.sh
sed -i -e "s|cpu: .*|cpu: 1|" -e "s|io: .*|io: 1|" /etc/sysconfig/imunify360/imunify360.config
systemctl restart imunify-antivirus
/usr/share/av-userside-plugin.sh
success_msg "ImunifyAV installed and configured"

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

# Install Redis
section_header "Installing and Configuring Redis"
process_step "Installing Redis"
dnf -y install redis
systemctl enable redis
systemctl start redis
success_msg "Redis service installed and started"
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
for php_version in "${PHP_VERSIONS[@]}"; do
    process_step "Installing Redis extension for $php_version"
    yes "no" | /opt/cpanel/${php_version}/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis
done

success_msg "Redis PHP extensions installed"

# Installing Engintron (Nginx for cPanel)
section_header "Installing and Configuring Engintron (Nginx)"
process_step "Downloading and installing Engintron"
curl -sSL https://raw.githubusercontent.com/engintron/engintron/master/engintron.sh | bash -s -- install
success_msg "Engintron (Nginx) installed"

# Calculate Nginx settings based on server resources
process_step "Configuring Nginx based on server resources"

# Get number of CPU cores
NGINX_CORES=$(grep -c ^processor /proc/cpuinfo)
log "Detected $NGINX_CORES CPU cores for Nginx worker processes"

# Calculate worker connections based on available memory
NGINX_WORKER_CONNECTIONS=1024
if [ $TOTAL_MEM_MB -ge 16384 ]; then # ≥16GB
    NGINX_WORKER_CONNECTIONS=4096
elif [ $TOTAL_MEM_MB -ge 8192 ]; then # ≥8GB
    NGINX_WORKER_CONNECTIONS=2048
fi
log "Setting Nginx worker connections to $NGINX_WORKER_CONNECTIONS"

# Calculate cache levels based on expected site count
if [[ "$SERVER_TYPE" == "shared" ]]; then
    CACHE_LEVELS="1:2" # For many sites (shared hosting)
else
    CACHE_LEVELS="1" # For fewer sites (personal server)
fi

# Create optimized Nginx configuration
process_step "Creating optimized Nginx configuration"

# Back up existing nginx.conf
if [ -f /etc/nginx/nginx.conf ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    log "Backed up existing nginx.conf"
fi

# Write optimized nginx.conf
cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;

# Load modular configuration files from the /etc/nginx/conf.d directory
# include /etc/nginx/conf.d/*.conf;

error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections $NGINX_WORKER_CONNECTIONS;
    use epoll;
    multi_accept on;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 10000;
    types_hash_max_size 2048;
    server_tokens off;
    server_names_hash_bucket_size 128;
    client_max_body_size 512M;

    # MIME Types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;

    # Logging Settings
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy;

    # FastCGI Cache Settings
    fastcgi_cache_path /var/cache/nginx/engintron levels=$CACHE_LEVELS keys_zone=engintron:25m inactive=30m max_size=256m;
    fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
    fastcgi_cache_use_stale error timeout invalid_header updating http_500 http_503;
    fastcgi_cache_valid 200 301 302 30s;
    fastcgi_cache_valid 404 10s;
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

    # File Cache Settings
    open_file_cache max=5000 inactive=30s;
    open_file_cache_valid 60s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # Rate Limiting
    limit_req_zone \$binary_remote_addr zone=protect_admin:10m rate=1r/s;

    # Proxy Cache Settings
    proxy_cache_path /var/cache/nginx/proxy levels=1:2 keys_zone=proxy_cache:10m max_size=128m inactive=60m;
    proxy_connect_timeout 240;
    proxy_send_timeout 240;
    proxy_read_timeout 240;
    proxy_buffer_size 4k;
    proxy_buffers 8 16k;
    proxy_busy_buffers_size 64k;
    proxy_temp_file_write_size 64k;
    proxy_temp_path /var/cache/nginx/proxy_temp;

    # Include Engintron config files
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/custom_rules;
}
EOF

# Generate dhparam.pem for better SSL security if it doesn't exist
if [ ! -d /etc/nginx/ssl ]; then
    mkdir -p /etc/nginx/ssl
fi

if [ ! -f /etc/nginx/ssl/dhparam.pem ]; then
    process_step "Generating DH parameters for SSL security (this may take a few minutes)"
    openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
fi

# Update Engintron custom_rules to optimize for cPanel
process_step "Updating Engintron custom rules"

# Backup custom_rules file
if [ -f /etc/nginx/custom_rules ]; then
    cp /etc/nginx/custom_rules /etc/nginx/custom_rules.backup
    log "Backed up custom_rules file"
fi

# Path to the Nginx custom rules file
CUSTOM_RULES="/etc/nginx/custom_rules"

# Uncomment line & set cPanel IP in custom_rules
sed -i "/^# set \$PROXY_DOMAIN_OR_IP/c\set \$PROXY_DOMAIN_OR_IP \"${SERVER_IP}\"; # Use your cPanel's shared IP address here" "$CUSTOM_RULES"

# Add line to disable Engintron micro-caching for dynamic sites
echo 'set $CACHE_BYPASS_FOR_DYNAMIC 1; # Disables micro-caching for most dynamic sites' >> "$CUSTOM_RULES"

# Add Cloudflare compatibility
echo '# Add Cloudflare IP addresses to X-Forwarded-For handling' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 103.21.244.0/22;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 103.22.200.0/22;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 103.31.4.0/22;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 104.16.0.0/13;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 104.24.0.0/14;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 108.162.192.0/18;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 131.0.72.0/22;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 141.101.64.0/18;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 162.158.0.0/15;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 172.64.0.0/13;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 173.245.48.0/20;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 188.114.96.0/20;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 190.93.240.0/20;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 197.234.240.0/22;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 198.41.128.0/17;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2400:cb00::/32;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2606:4700::/32;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2803:f800::/32;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2405:b500::/32;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2405:8100::/32;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2c0f:f248::/32;' >> "$CUSTOM_RULES"
echo 'set_real_ip_from 2a06:98c0::/29;' >> "$CUSTOM_RULES"
echo 'real_ip_header CF-Connecting-IP;' >> "$CUSTOM_RULES"

# Create cache directory if it doesn't exist
if [ ! -d /var/cache/nginx/engintron ]; then
    mkdir -p /var/cache/nginx/engintron
    chmod 755 /var/cache/nginx/engintron
fi

if [ ! -d /var/cache/nginx/proxy ]; then
    mkdir -p /var/cache/nginx/proxy
    mkdir -p /var/cache/nginx/proxy_temp
    chmod 755 /var/cache/nginx/proxy
    chmod 755 /var/cache/nginx/proxy_temp
fi

# Create a custom configuration for static file caching
process_step "Creating browser caching rules for static files"
cat > /etc/nginx/conf.d/browser_caching.conf << EOF
# Browser caching rules
map \$sent_http_content_type \$expires {
    default                    off;
    text/html                  epoch;
    text/css                   max;
    application/javascript     max;
    ~image/                    max;
    ~font/                     max;
    application/x-font-ttf     max;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    # This is a placeholder server block that will be overridden by Engintron's configuration
    # We're just using it to define global settings
    
    expires \$expires;
    
    # Add security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Frame-Options SAMEORIGIN;
    
    # Additional security for PHP files
    location ~* \\.php\$ {
        # Prevent direct access to .php files from Nginx
        # These will be handled by Apache backend
        return 403;
    }
    
    # Deny access to specific files and directories
    location ~* (\\.user.ini|\\.htaccess|\\.git|\\.svn|\\.project|LICENSE|README) {
        deny all;
    }
}
EOF

# Restart Engintron and Apache to apply changes
process_step "Applying Nginx and Apache configuration changes"
bash /engintron.sh res
success_msg "Engintron (Nginx) configured with optimized settings"

process_step "Testing Nginx configuration"
nginx -t
if [ $? -eq 0 ]; then
    success_msg "Nginx configuration test passed"
else
    warning_msg "Nginx configuration test failed - please check the logs for errors"
    # Restore backup if test fails
    if [ -f /etc/nginx/nginx.conf.backup ]; then
        cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
        log "Restored backup nginx.conf due to test failure"
    fi
fi

# PHP performance tuning and system hardening
section_header "PHP Performance Tuning & System Hardening"
check_cpanel_license
tune_php_opcache
tune_php_fpm_pools
secure_tmp

# Setup login info script
process_step "Setting up login information script"
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
bctr "$BLUE" "${GREEN}INSTALLATION COMPLETE"
bsep "$BLUE"
brow "$BLUE" ""
brow "$BLUE" " ${WHITE}Your server has been successfully configured and secured."
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Server Information:"
brow "$BLUE" " ${GREEN}• IP Address:${NC} $SERVER_IP"
brow "$BLUE" " ${GREEN}• SSH Port:${NC} $SSH_PORT"
brow "$BLUE" " ${GREEN}• Hostname:${NC} server.$domain"
brow "$BLUE" " ${GREEN}• Server Type:${NC} $([ "$SERVER_TYPE" == "personal" ] && echo "Personal" || echo "Shared Hosting")"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Web Server Configuration:"
brow "$BLUE" " ${GREEN}• Nginx + Apache Setup:${NC} Engintron"
brow "$BLUE" " ${GREEN}• Apache MaxRequestWorkers:${NC} $FINAL_MRW"
brow "$BLUE" " ${GREEN}• MySQL Buffer Pool:${NC} $BPOOL"
brow "$BLUE" ""

# Add resource allocation disclaimer for Personal servers
if [[ "$SERVER_TYPE" == "personal" ]]; then
    brow "$BLUE" " ${YELLOW}Resource Allocation:"
    brow "$BLUE" " ${WHITE}• Resources are optimized with a Nginx+Apache stack:"
    brow "$BLUE" " ${WHITE}  - 10% Nginx, 25% Apache, 30% MySQL, and 35% for the OS"
    brow "$BLUE" " ${WHITE}• These settings are automatically tuned to your server's resources"
    brow "$BLUE" " ${WHITE}  and can be further optimized based on traffic patterns."
    brow "$BLUE" ""
fi

brow "$BLUE" " ${YELLOW}Nginx Advantages:"
brow "$BLUE" " ${WHITE}• Faster performance with static content caching"
brow "$BLUE" " ${WHITE}• Better handling of concurrent connections"
brow "$BLUE" " ${WHITE}• Reduced server load with efficient request handling"
brow "$BLUE" " ${WHITE}• Enhanced security with additional layer before Apache"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Access Information:"
brow "$BLUE" " ${GREEN}• WHM URL:${NC} https://$SERVER_IP:2087"
brow "$BLUE" " ${GREEN}• cPanel URL:${NC} https://$SERVER_IP:2083"
brow "$BLUE" " ${RED}  (Ignore self-signed SSL warnings until domain SSL is setup)"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}Security Features:"
brow "$BLUE" " ${GREEN}• CSF Firewall:${NC} Enabled with DDoS protection"
brow "$BLUE" " ${GREEN}• ModSecurity:${NC} Enabled with OWASP ruleset"
brow "$BLUE" " ${GREEN}• ImunifyAV:${NC} Installed and configured"
brow "$BLUE" " ${GREEN}• Nginx Security:${NC} Additional protection layer configured"
brow "$BLUE" ""
brow "$BLUE" " ${YELLOW}IMPORTANT:"
brow "$BLUE" " ${WHITE}• MySQL Root Password has been set and saved in /root/.my.cnf"
brow "$BLUE" " ${WHITE}• All details are logged in ${GREEN}/root/panelbot-serversetup.log"
brow "$BLUE" ""
bsep "$BLUE"
brow "$BLUE" ""
brow "$BLUE" " ${CYAN}If you found this script helpful, please consider supporting:"
brow "$BLUE" " ${WHITE}☕ https://ko-fi.com/ahtshamjutt"
brow "$BLUE" ""
bbot "$BLUE"
echo ""
echo -e "${YELLOW}A system reboot is required to complete the setup.${NC}"
echo -e "${GREEN}Please run 'reboot' when you're ready.${NC}"
echo ""

# Log final information
log "Installation completed successfully!"
log "Server IP: $SERVER_IP"
log "SSH Port: $SSH_PORT" 
log "Server Type: $SERVER_TYPE"
log "Apache MaxRequestWorkers: $FINAL_MRW"
log "MySQL Buffer Pool: $BPOOL"
log "Nginx Configuration: Engintron (optimized)"
log "WHM URL: https://$SERVER_IP:2087"
log "Installation completed at $(date)"