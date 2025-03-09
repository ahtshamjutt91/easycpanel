#!/bin/bash
# revert-optimization.sh
# Universal reversal script for undoing changes made by either optimize-apache.sh or optimize-nginx.sh
# Created by Ahtsham Jutt

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Define the log file location
LOG_FILE="/root/panelbot-reversion.log"

# Function to add a log entry and echo it to the terminal
log() {
    # Add timestamped entry to log file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@" >> "${LOG_FILE}"
    # Display clean message without timestamp on screen
    echo -e "${CYAN}$@${NC}"
}

# Function to display section headers with pause
section_header() {
    echo -e "\n${BLUE}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${WHITE} $1 ${BLUE}│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────┘${NC}"
    log "$1"
    
    # Pause for readability (2 seconds)
    sleep 2
}

# Function to display process steps
process_step() {
    echo -e "${YELLOW}➤${NC} $@"
    sleep 1
}

# Function to display success message
success_msg() {
    echo -e "${GREEN}✓${NC} $@"
    log "$@"
}

# Function to display error message
error_msg() {
    echo -e "${RED}✗${NC} $@"
    log "ERROR: $@"
}

# Function to display warning message
warning_msg() {
    echo -e "${YELLOW}⚠${NC} $@"
    log "WARNING: $@"
}

# Function to check if a file exists
file_exists() {
    if [ -f "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if a directory exists
dir_exists() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Function to restore a file from backup
restore_file() {
    local backup_file="$1"
    local target_file="$2"
    
    if [ -f "$backup_file" ]; then
        cp -f "$backup_file" "$target_file"
        log "Restored: $target_file"
        return 0
    else
        log "Warning: Backup file $backup_file does not exist, cannot restore"
        return 1
    fi
}

# Function to restart a service safely
restart_service() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        systemctl restart "$service"
        log "Restarted service: $service"
        return 0
    else
        log "Warning: Service $service is not active, starting it"
        systemctl start "$service"
        return 1
    fi
}

# Check for Root Privileges
if [[ $EUID -ne 0 ]]; then
   error_msg "This script must be run as root!"
   exit 1
fi

# Clear the screen for a clean look
clear

# Display a compact banner
echo -e "${BLUE}┌────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${GREEN}          cPanel Optimization Reversal Script            ${BLUE}│${NC}"
echo -e "${BLUE}│${YELLOW}              Created by Ahtsham Jutt                   ${BLUE}│${NC}"
echo -e "${BLUE}│${WHITE}       Website: ahtshamjutt.com | me@ahtshamjutt.com     ${BLUE}│${NC}"
echo -e "${BLUE}│${CYAN}       Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕         ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────┘${NC}"

# Display reversal notice
echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│${WHITE}                      IMPORTANT NOTICE                         ${YELLOW}│${NC}"
echo -e "${YELLOW}├─────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${YELLOW}│${WHITE} • This script will revert your server to its state before      ${YELLOW}│${NC}"
echo -e "${YELLOW}│${WHITE}   optimization by restore from backup.                         ${YELLOW}│${NC}"
echo -e "${YELLOW}│                                                                 ${YELLOW}│${NC}"
echo -e "${YELLOW}│${WHITE} • A reboot is recommended after the reversion process.         ${YELLOW}│${NC}"
echo -e "${YELLOW}│${WHITE} • All changes will be logged to $LOG_FILE      ${YELLOW}│${NC}"
echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
sleep 3

# Scan for backup directories
section_header "Scanning for Backup Directories"
process_step "Looking for backups in /backup/panelbot-* directories"

# Find Apache optimization backups
APACHE_BACKUPS=()
if dir_exists "/backup/panelbot-backup"; then
    APACHE_DIRS=$(find /backup/panelbot-backup -maxdepth 1 -type d -name "*" | sort -r)
    for dir in $APACHE_DIRS; do
        if [ "$dir" != "/backup/panelbot-backup" ]; then
            if dir_exists "$dir/apache"; then
                APACHE_BACKUPS+=("$dir")
            fi
        fi
    done
fi

# Find Nginx optimization backups
NGINX_BACKUPS=()
if dir_exists "/backup/panelbot-nginx-backup"; then
    NGINX_DIRS=$(find /backup/panelbot-nginx-backup -maxdepth 1 -type d -name "*" | sort -r)
    for dir in $NGINX_DIRS; do
        if [ "$dir" != "/backup/panelbot-nginx-backup" ]; then
            if dir_exists "$dir/nginx" || dir_exists "$dir/engintron"; then
                NGINX_BACKUPS+=("$dir")
            fi
        fi
    done
fi

# Check if we found any backups
if [ ${#APACHE_BACKUPS[@]} -eq 0 ] && [ ${#NGINX_BACKUPS[@]} -eq 0 ]; then
    error_msg "No optimization backups found! Cannot proceed with reversion."
    exit 1
fi

# Show found backups
section_header "Available Backup Sets"

echo -e "${WHITE}The following backups were found:${NC}"
echo -e ""

# List Apache backups
if [ ${#APACHE_BACKUPS[@]} -gt 0 ]; then
    echo -e "${GREEN}Apache Optimization Backups:${NC}"
    for i in "${!APACHE_BACKUPS[@]}"; do
        BACKUP_DATE=$(basename "${APACHE_BACKUPS[$i]}" | sed 's/^[^0-9]*//')
        FORMATTED_DATE=$(date -d "${BACKUP_DATE:0:8} ${BACKUP_DATE:9:2}:${BACKUP_DATE:11:2}:${BACKUP_DATE:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        if [ $? -ne 0 ]; then
            FORMATTED_DATE="Unknown Date"
        fi
        echo -e "${WHITE}$((i+1)).${NC} ${YELLOW}Apache${NC} backup from ${GREEN}$FORMATTED_DATE${NC} (${CYAN}${APACHE_BACKUPS[$i]}${NC})"
    done
    echo -e ""
fi

# List Nginx backups
APACHE_OFFSET=${#APACHE_BACKUPS[@]}
if [ ${#NGINX_BACKUPS[@]} -gt 0 ]; then
    echo -e "${GREEN}Nginx Optimization Backups:${NC}"
    for i in "${!NGINX_BACKUPS[@]}"; do
        BACKUP_DATE=$(basename "${NGINX_BACKUPS[$i]}" | sed 's/^[^0-9]*//')
        FORMATTED_DATE=$(date -d "${BACKUP_DATE:0:8} ${BACKUP_DATE:9:2}:${BACKUP_DATE:11:2}:${BACKUP_DATE:13:2}" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        if [ $? -ne 0 ]; then
            FORMATTED_DATE="Unknown Date"
        fi
        echo -e "${WHITE}$((i+1+APACHE_OFFSET)).${NC} ${YELLOW}Nginx${NC} backup from ${GREEN}$FORMATTED_DATE${NC} (${CYAN}${NGINX_BACKUPS[$i]}${NC})"
    done
    echo -e ""
fi

# Prompt user to select a backup
echo -e "${WHITE}Which backup would you like to restore from? (Enter the number)${NC}"
read -p "▶ " BACKUP_CHOICE

# Validate and process the selection
if ! [[ "$BACKUP_CHOICE" =~ ^[0-9]+$ ]]; then
    error_msg "Invalid input. Please enter a number."
    exit 1
fi

# Determine which backup set was chosen
if [ $BACKUP_CHOICE -le $APACHE_OFFSET ] && [ $BACKUP_CHOICE -ge 1 ]; then
    # Apache backup selected
    BACKUP_INDEX=$((BACKUP_CHOICE-1))
    BACKUP_DIR="${APACHE_BACKUPS[$BACKUP_INDEX]}"
    BACKUP_TYPE="apache"
    log "Selected Apache backup: $BACKUP_DIR"
elif [ $BACKUP_CHOICE -le $((APACHE_OFFSET + ${#NGINX_BACKUPS[@]})) ] && [ $BACKUP_CHOICE -gt $APACHE_OFFSET ]; then
    # Nginx backup selected
    BACKUP_INDEX=$((BACKUP_CHOICE-APACHE_OFFSET-1))
    BACKUP_DIR="${NGINX_BACKUPS[$BACKUP_INDEX]}"
    BACKUP_TYPE="nginx"
    log "Selected Nginx backup: $BACKUP_DIR"
else
    error_msg "Invalid selection. Please run the script again and select a valid number."
    exit 1
fi

# Verification step
echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│${WHITE}                    CONFIRMATION REQUIRED                      ${YELLOW}│${NC}"
echo -e "${YELLOW}├─────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${YELLOW}│${WHITE} You've selected to restore from:                              ${YELLOW}│${NC}"
echo -e "${YELLOW}│${GREEN} $BACKUP_DIR ${YELLOW}│${NC}"
echo -e "${YELLOW}│                                                                 ${YELLOW}│${NC}"
echo -e "${YELLOW}│${WHITE} This will revert all optimization changes and restore your    ${YELLOW}│${NC}"
echo -e "${YELLOW}│${WHITE} server to its previous state. This cannot be undone.          ${YELLOW}│${NC}"
echo -e "${YELLOW}│                                                                 ${YELLOW}│${NC}"
echo -e "${YELLOW}│${RED} All current server configurations will be overwritten!        ${YELLOW}│${NC}"
echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"
echo -e ""
echo -e "${WHITE}Are you sure you want to proceed with this restoration? (yes/no)${NC}"
read -p "▶ " CONFIRMATION

if [[ ! "$CONFIRMATION" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Reversal cancelled. No changes were made.${NC}"
    exit 0
fi

# Begin the reversion process
section_header "Starting Reversion Process"
process_step "Checking backup manifest and state logs"

# Check for manifest file
MANIFEST_FILE="$BACKUP_DIR/backup_manifest.log"
if ! file_exists "$MANIFEST_FILE"; then
    warning_msg "Backup manifest not found at $MANIFEST_FILE"
    warning_msg "Will attempt to restore using standard paths"
else
    success_msg "Found backup manifest: $MANIFEST_FILE"
    # Count the backup entries
    BACKUP_ENTRY_COUNT=$(grep -c "=>" "$MANIFEST_FILE")
    log "Backup contains $BACKUP_ENTRY_COUNT entries"
fi

# Check for nginx state log if it's a nginx backup
if [ "$BACKUP_TYPE" = "nginx" ]; then
    NGINX_STATE_FILE="$BACKUP_DIR/nginx_state.log"
    if file_exists "$NGINX_STATE_FILE"; then
        success_msg "Found Nginx state log: $NGINX_STATE_FILE"
        source "$NGINX_STATE_FILE"
        log "Original Nginx state loaded"
    else
        warning_msg "Nginx state log not found. Some restoration steps may be skipped."
    fi
fi

# Create a pre-reversion backup
REVERSION_BACKUP_DIR="/backup/pre-reversion-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REVERSION_BACKUP_DIR"
log "Created pre-reversion backup directory: $REVERSION_BACKUP_DIR"

# Backup current configuration files that will be changed
process_step "Creating backup of current configuration before reversion"

# Backup key files
if file_exists "/etc/my.cnf"; then
    cp -f /etc/my.cnf "$REVERSION_BACKUP_DIR/my.cnf"
fi

if file_exists "/etc/apache2/conf.d/includes/pre_main_global.conf"; then
    cp -f /etc/apache2/conf.d/includes/pre_main_global.conf "$REVERSION_BACKUP_DIR/pre_main_global.conf"
fi

if file_exists "/etc/cpanel/ea4/ea4.conf"; then
    cp -f /etc/cpanel/ea4/ea4.conf "$REVERSION_BACKUP_DIR/ea4.conf"
fi

if file_exists "/etc/csf/csf.conf"; then
    cp -f /etc/csf/csf.conf "$REVERSION_BACKUP_DIR/csf.conf"
fi

if [ "$BACKUP_TYPE" = "nginx" ]; then
    if file_exists "/etc/nginx/nginx.conf"; then
        cp -f /etc/nginx/nginx.conf "$REVERSION_BACKUP_DIR/nginx.conf"
    fi
    
    if dir_exists "/etc/nginx/conf.d"; then
        mkdir -p "$REVERSION_BACKUP_DIR/nginx_conf.d"
        cp -rf /etc/nginx/conf.d/* "$REVERSION_BACKUP_DIR/nginx_conf.d/"
    fi
fi

success_msg "Pre-reversion backup completed"

# Start the actual restoration process
section_header "Restoring Configuration Files"

# Restore Apache configuration
if dir_exists "$BACKUP_DIR/apache"; then
    process_step "Restoring Apache configuration"
    
    # Restore Apache main configuration
    if file_exists "$BACKUP_DIR/apache/pre_main_global.conf"; then
        restore_file "$BACKUP_DIR/apache/pre_main_global.conf" "/etc/apache2/conf.d/includes/pre_main_global.conf"
    fi
    
    # Restore EasyApache configuration
    if file_exists "$BACKUP_DIR/apache/ea4.conf"; then
        restore_file "$BACKUP_DIR/apache/ea4.conf" "/etc/cpanel/ea4/ea4.conf"
    fi
    
    # Restore Apache httpd.conf if it exists in backup
    if file_exists "$BACKUP_DIR/apache/httpd.conf"; then
        restore_file "$BACKUP_DIR/apache/httpd.conf" "/etc/apache2/conf/httpd.conf"
    fi
    
    success_msg "Apache configuration restored"
fi

# Restore MySQL configuration
if file_exists "$BACKUP_DIR/mysql/my.cnf"; then
    process_step "Restoring MySQL configuration"
    restore_file "$BACKUP_DIR/mysql/my.cnf" "/etc/my.cnf"
    success_msg "MySQL configuration restored"
fi

# Restore PHP configuration
if dir_exists "$BACKUP_DIR/php"; then
    process_step "Restoring PHP configuration"
    PHP_FILES=$(find "$BACKUP_DIR/php" -type f -name "*.ini")
    for php_file in $PHP_FILES; do
        php_filename=$(basename "$php_file")
        # Find the matching PHP version
        for php_version in ea-php{70..84}; do
            target_path="/opt/cpanel/$php_version/root/etc/php.ini"
            if [ -f "$target_path" ]; then
                if [ "$php_filename" = "php.ini" ]; then
                    restore_file "$php_file" "$target_path"
                    break
                fi
            fi
        done
    done
    success_msg "PHP configuration restored"
fi

# Restore CSF Firewall configuration
if file_exists "$BACKUP_DIR/csf/csf.conf"; then
    process_step "Restoring CSF Firewall configuration"
    restore_file "$BACKUP_DIR/csf/csf.conf" "/etc/csf/csf.conf"
    success_msg "CSF Firewall configuration restored"
fi

# Handle Nginx/Engintron restoration if applicable
if [ "$BACKUP_TYPE" = "nginx" ]; then
    section_header "Restoring Nginx Configuration"
    
    # First determine if we need to remove Engintron
    if [ "${ENGINTRON_INSTALLED:-false}" = "false" ]; then
        process_step "Removing Engintron (not present in original setup)"
        if [ -f "/engintron.sh" ]; then
            bash /engintron.sh remove
            success_msg "Engintron removed successfully"
        else
            warning_msg "Engintron control script not found, attempting manual removal"
            systemctl stop nginx
            systemctl disable nginx
            success_msg "Nginx service stopped and disabled"
        fi
    else
        # Restore Engintron configuration
        process_step "Restoring Engintron configuration"
        if dir_exists "$BACKUP_DIR/engintron"; then
            if file_exists "$BACKUP_DIR/engintron/nginx.conf"; then
                restore_file "$BACKUP_DIR/engintron/nginx.conf" "/etc/nginx/nginx.conf"
            fi
            
            if file_exists "$BACKUP_DIR/engintron/custom_rules"; then
                restore_file "$BACKUP_DIR/engintron/custom_rules" "/etc/nginx/custom_rules"
            fi
            
            # Restore any conf.d files
            if dir_exists "$BACKUP_DIR/engintron/conf.d"; then
                mkdir -p "/etc/nginx/conf.d"
                cp -rf "$BACKUP_DIR/engintron/conf.d/"* "/etc/nginx/conf.d/"
                log "Restored Nginx conf.d directory"
            fi
            
            success_msg "Engintron configuration restored"
        fi
    fi
    
    # Handle cPanel Nginx if it was previously installed
    if [ "${CPANEL_NGINX_INSTALLED:-false}" = "true" ]; then
        process_step "Reinstalling cPanel Nginx (was present in original setup)"
        if dir_exists "$BACKUP_DIR/cpanel_nginx"; then
            /scripts/setupnginx
            systemctl enable nginx
            systemctl start nginx
            success_msg "cPanel Nginx reinstalled"
        else
            warning_msg "Cannot restore cPanel Nginx configuration (backup not found)"
            /scripts/setupnginx
            success_msg "cPanel Nginx reinstalled with default configuration"
        fi
    fi
fi

# Rebuild and restart services
section_header "Rebuilding and Restarting Services"

process_step "Rebuilding Apache configuration"
/scripts/rebuildhttpdconf
success_msg "Apache configuration rebuilt"

process_step "Restarting services"
/scripts/restartsrv_httpd
systemctl restart mysqld
csf -r

# Restart Nginx/Engintron if applicable
if [ "$BACKUP_TYPE" = "nginx" ] && [ "${ENGINTRON_INSTALLED:-false}" = "true" ]; then
    if [ -f "/engintron.sh" ]; then
        bash /engintron.sh res
        success_msg "Engintron services restarted"
    else
        systemctl restart nginx
        success_msg "Nginx service restarted"
    fi
fi

# Final success message
clear
echo -e "${BLUE}┌───────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${GREEN}                      REVERSION COMPLETED                          ${BLUE}│${NC}"
echo -e "${BLUE}├───────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}│ ${WHITE}Your server has been successfully reverted to its previous state.  ${BLUE}│${NC}"
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}│ ${YELLOW}Reversion Summary:                                                 ${BLUE}│${NC}"
echo -e "${BLUE}│ ${GREEN}• Restored from:${NC} $BACKUP_DIR                  ${BLUE}│${NC}"
echo -e "${BLUE}│ ${GREEN}• Backup Type:${NC} $BACKUP_TYPE                                               ${BLUE}│${NC}"
echo -e "${BLUE}│ ${GREEN}• Pre-reversion Backup:${NC} $REVERSION_BACKUP_DIR      ${BLUE}│${NC}"
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}│ ${YELLOW}Services Restarted:                                               ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}• Apache                                                           ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}• MySQL                                                            ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}• CSF Firewall                                                     ${BLUE}│${NC}"
if [ "$BACKUP_TYPE" = "nginx" ]; then
echo -e "${BLUE}│ ${WHITE}• Nginx/Engintron                                                  ${BLUE}│${NC}"
fi
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}│ ${YELLOW}Next Steps:                                                       ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}• A system reboot is recommended to complete the reversion         ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}• Verify your services are functioning correctly                   ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}• Review the log file at $LOG_FILE        ${BLUE}│${NC}"
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}├───────────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}│ ${CYAN}If you found this script helpful, please consider supporting:         ${BLUE}│${NC}"
echo -e "${BLUE}│ ${WHITE}☕ https://ko-fi.com/ahtshamjutt                                     ${BLUE}│${NC}"
echo -e "${BLUE}│                                                                       │${NC}"
echo -e "${BLUE}└───────────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${YELLOW}A system reboot is recommended to complete the reversion.${NC}"
echo -e "${GREEN}Please run 'reboot' when convenient.${NC}"
echo ""

# Log final information
log "Reversion completed successfully!"
log "Reverted from: $BACKUP_DIR"
log "Backup type: $BACKUP_TYPE"
log "Pre-reversion backup: $REVERSION_BACKUP_DIR"
log "Reversion completed at $(date)"