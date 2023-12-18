#!/bin/bash
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Confiugration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#              (Created by Panel Bot panelbot.io)                    #"
echo "#              Email for queries: info@panelbot.io                   #"
echo "#                                                                    #"
echo "######################################################################"
echo ""
sleep 2

# Check for Root Privileges
if [[ $EUID -ne 0 ]]; then
   printf "This script must be run as root\n" 
   exit 1
fi

# Define the log file location
LOG_FILE="/root/panelbot-serversetup.log"

# Function to add a log entry and echo it to the terminal
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@" | tee -a "${LOG_FILE}"
}
echo ""
echo "############ PLEASE MAKE SURE YOU HAVE ACTIVE CPANEL LICENSE FOR THIS SERVER / SERVER IP ############" 
echo ""
sleep 2
echo ""
echo "###############################################################################################"
echo "" 
log "========== Some information is required to setup your Server configuration, nameservers and hostname =========="
sleep 1
echo ""
clear
log "========== Please provide your Domain / Website URL you would like to host, Example: panelbot.io =========="
read domain
sleep 1
echo ""
log "========== Please provide your Email Address where you would like to receive Server Alerts =========="
read email
echo ""
sleep 2
clear 

# This will Get the Server Main IP to configure in cPanel and Server.
log "Fetching Server's Main IP Address."
serverip=$(hostname -I | awk ' {print $1}') ;
sleep 2
log "Found Server's Main IP Address as $serverip"
sleep 2
echo ""
echo ""
clear
echo ""
echo ""
echo ""
clear 
log "######################################################################"
log "#                                                                    #"
log "#               Installing cPanel/WHM & Securing it                  #"
log "#                                                                    #"
log "#                     Please Sit Back & Enjoy                        #"
log "#              This Process will take some time!                     #"
log "#                                                                    #"
log "######################################################################"
sleep 2
echo ""
echo ""
echo ""
clear
log "============= Updating System Pacakges & defining required values! ============="

# Installing Important Linux Modules and Disabling NetworkManager as cPanel does not work with the NetworkManager being enabled.
log "Running dnf update to update OS Packages!"
sudo dnf update -y ;
log "Update completed!"
echo ""

log "Installing wget function."
sudo dnf install wget -y ;
log "Linux Wget function is installed and enabled."
sleep 1

log "Stopping and disabling NetworkManager and disabling SELINUX."
systemctl stop NetworkManager ;
systemctl disable NetworkManager ;
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config ;
log "NetworkManager stopped and disabled."
log "Selinux Disabled."
echo ""
sleep 1
clear
log "Starting cPanel/WHM Installation."
sleep 2
cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest ;

echo ""
log "Fetching Server's Network Interface."
# Try to find venet0 interface first, common in OpenVZ/Virtuozzo
INTERFACE=$(ip a | grep venet0:0 | awk '{print $2}' | cut -d ':' -f 1)

# If venet0 is not found, find the primary network interface
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip route | grep default | awk '{print $5}')
fi
sleep 1
log "Found Server's Network Interface."
sleep 1
log "Configuring WHM/cPanel basic configuration, including Server IP, Contact Email, Server Interface and Server Nameservers."
# This option will reconfigure the basic configuration of cPanel and will update the main Server IP, customer Email, and Nameservers.
sudo touch /etc/.whostmgrft ;
sudo mv /etc/wwwacct.conf /etc/wwwacct.conf.bk ;
echo "ADDR $serverip
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
" >> /etc/wwwacct.conf ;
sleep 1
log "Done, continuing!"
sleep 1
clear
echo ""
log "========== Setting Server Hostname, Make sure to Add A record for server.$domain with Server IP $serverip =========="

# Changing the system hostname
hostnamectl set-hostname server.$domain ;

# Changing the hostname in cPanel configuration
/usr/local/cpanel/bin/set_hostname server.$domain ;

# Restarting necessary services
/scripts/restartsrv_cpsrvd ;
/scripts/restartsrv_httpd ;
echo ""
log "Server Hostname is configured."
sleep 1

# This will enable thr Initial Disk Space Quotas for the Server.
log "Enabling / Updating initial quotas! A reboot in the end will be required."
yes |  /scripts/initquotas ;
sleep 2
log "Server quotas are enabled!"
clear ;
sleep 2
echo ""

# Configuring Apache Event Module
log "=========== Configuring Apache Web Server for PHP-FPM =========="
sleep 2

echo ""
# Create Apache configuration
cat <<EOL > /etc/apache2/conf.d/includes/pre_main_global.conf
<IfModule event.c>
    ServerLimit 16
    StartServers 3
    MinSpareThreads 25
    MaxSpareThreads 75
    ThreadsPerChild 64
    MaxRequestWorkers 400
    MaxConnectionsPerChild 0
</IfModule>
EOL

# Making a Backup of EasyApache Profile in case we need it and Adjusting the Settings!
sudo cp /etc/cpanel/ea4/ea4.conf /etc/cpanel/ea4/ea4.conf-bak ;
sed -i \
-e 's/\(maxclients[" ]*:\)\s[0-9"]\+/\1 400/' \
-e 's/\(maxrequestsperchild[" ]*:\)\s[0-9"]\+/\1 0/' \
-e 's/\(serverlimit[" ]*:\)\s[0-9"]\+/\1 16/' \
-e 's/\(startservers[" ]*:\)\s[0-9"]\+/\1 3/' \
-e 's/\(symlink_protect[" ]*:\)\s[A-Za-z0-9"]\+/\1 "On"/' \
-e 's/\(threadsperchild[" ]*:\)\s[0-9"]\+/\1 64/' \
/etc/cpanel/ea4/ea4.conf ;

log "Apache configuration has been updated based on the server's hardware resources."

echo ""
clear ;
sleep 1
log "=========== Configuring EasyApache4, installing PHP versions, PHP extensions & Apache modules! =========="
echo ""
log "this process will take few minutes, Please wait!"
echo "....."
sleep 1
echo "...."
sleep 1
echo "..."
sleep 1
echo ".."
sleep 2
echo "."
echo ""
sleep 2

# This will download and install the custom PHP Profile with all the required PHP versions and PHP Extensions required for websites, CMS scripts and Server.
mkdir /etc/cpanel/ea4/profiles/custom/ ; #Create directory if it doesnt already exist!
cp /root/easycpanel/event-php82818074-phpfpm.json /etc/cpanel/ea4/profiles/custom/ ;
yes | /usr/local/bin/ea_install_profile --install /etc/cpanel/ea4/profiles/custom/event-php82818074-phpfpm.json ;
echo ""
echo ""
sleep 1
log "EasyApache4 is configured with required Apache modules, PHP versions and PHP extensions."
log "PHP version 7.4, PHP version 8.0, PHP 8.1 & PHP version 8.2 are installed"
echo ""
sleep 1
echo ""

# This will setup the Server default PHP version to PHP 8.1 version.
log "Setting up default PHP Version"
whmapi1 php_set_system_default_version version=ea-php81 ;
whmapi1 php_get_installed_versions | awk '/ea-php/ {print $2}' | xargs -i -n1 whmapi1 php_set_handler version='{}' handler='cgi' ;
/usr/local/cpanel/scripts/restartsrv_cpsrvd ;
echo ""
echo "..."
sleep 1
echo ".."
sleep 1
echo "."
sleep 1
echo ""
log "PHP 8.1 is set as default PHP version for the server"
echo ""
sleep 4
clear ;
log "========== Updating PHP memory_limit and other values, Please wait! =========="
echo "....."
sleep 1
echo "...."
sleep 1
echo "..."
sleep 1
echo ".."
sleep 1
echo "."
echo ""
sleep 1

# This will update the required values for all the PHP versions to run websites smoothly. 
whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php74'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php74'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php74'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php74'

sleep 1
log "PHP 7.4 is configured with the following configuration,"
log "Memory_limit: 256M"
log "Post_max_size: 512M"
log "Upload_max_filesize: 512M"
log "Max_input-var: 10,000"
sleep 2

log "Continuing!"

whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php80'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php80'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php80'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php80'

sleep 1
log "PHP 8.0 is configured with the following configuration,"
log "Memory_limit: 256M"
log "Post_max_size: 512M"
log "Upload_max_filesize: 512M"
log "Max_input-var: 10,000"
sleep 2

log "Continuing!"

whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php81'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php81'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php81'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php81'

sleep 1
log "PHP 8.1 is configured with the following configuration,"
log "Memory_limit: 256M"
log "Post_max_size: 512M"
log "Upload_max_filesize: 512M"
log "Max_input-var: 10,000"
sleep 2

log "Continuing!"

whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php82'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php82'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php82'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php82'

sleep 1
log "PHP 8.2 is configured with the following configuration,"
log "Memory_limit: 256M"
log "Post_max_size: 512M"
log "Upload_max_filesize: 512M"
log "Max_input-var: 10,000"
sleep 2

log "PHP configuration is completed."
log "PHP Configuration can be managed through WHM -> MultiPHP Editor option."
sleep 1

whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm='1'
/scripts/restartsrv_apache_php_fpm ;
log "Enabled PHP-FPM by default for New Accounts."

printf "php_value_open_basedir: { name: 'php_value[open_basedir]', value: \"[%% documentroot %%]:[%% homedir %%]:/var/cpanel/php/sessions/[%% ea_php_version %%]:/tmp:/var/tmp\" }\n" >> /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml ;
/scripts/php_fpm_config --rebuild ;
echo ""
sleep 1
echo ""
log "PHP values for all PHP versions are updated!"
clear 
sleep 2
echo ""
log "========== Install Memcache & Securing it =========="
sleep 1

# This will install, enable and secure Memcached for the cPanel Server.
dnf -y install memcached ;
systemctl enable memcached ;
perl -pi -e "s/OPTIONS=""/OPTIONS="-l 127.0.0.1 -U 0"/g" /etc/sysconfig/memcached ;
systemctl restart memcached ;
log "Memcache is installed and secured, continuing"
echo ""
sleep 1
clear
log "========== Installing ImageMagick with ImageMagick PHP Extensions ==========="
sleep 1

# This will install and configure the ImageMagick for all the PHP versions installed on Server. 
echo ""
dnf config-manager --set-enabled epel ;
dnf install ImageMagick ImageMagick-devel -y ;
yes | /opt/cpanel/ea-php74/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php80/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php81/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php82/root/usr/bin/pecl install imagick ;
/scripts/restartsrv_apache_php_fpm ;

log "Installed ImageMagick on PHP 7.4, PHP 8.0, PHP 8.1 and PHP 8.2 alongside their PHP Extension."
sleep 2
echo ""
log "Done, continuing..."
echo ""
clear
echo ""

# Setting up ~/.my.cnf and /etc/my.cnf file for basic MySQL Service Optimization and Configuration
log "=========== Setting up MySQL Root Password and Configuring MySQL my.cnf File =========="

# Generate a random strong password for MySQL
ROOT_PASS=$(openssl rand -base64 12)

# Move existing .my.cnf to .my.cnf-bak if already exist!
if [ -f ~/.my.cnf ]; then
    mv ~/.my.cnf ~/.my.cnf-bak
fi

# Create new .my.cnf and set up root password
(cat <<EOF
[client]
user=root
password=${ROOT_PASS}
EOF
) > ~/.my.cnf

log "Configured .my.cnf file for easy MySQL Usage!"
sleep 1

# Change permissions to only allow user to read and write
chmod 600 ~/.my.cnf

# Backup existing /etc/my.cnf to /etc/my.cnf-bak if already exist!
if [ -f /etc/my.cnf ]; then
    sudo mv /etc/my.cnf /etc/my.cnf-bak
fi

# Create new /etc/my.cnf with the specified configurations
(cat <<EOF
[mysqld]
pid-file                = /var/run/mysqld/mysqld.pid
socket                  = /var/run/mysqld/mysqld.sock
datadir                 = /var/lib/mysql
key_buffer_size         = 16M
max_allowed_packet      = 32M
thread_stack            = 256K
thread_cache_size       = 4
# InnoDB Settings
innodb_buffer_pool_size = 1G
innodb_redo_log_capacity = 256M
innodb_file_per_table   = 1
innodb_thread_concurrency = 4
innodb_flush_log_at_trx_commit = 2
# Logging
log_error               = /var/lib/mysql/error.log
# Connection Settings
max_connections         = 151
wait_timeout            = 180
interactive_timeout     = 180
# Table and Open Files
table_open_cache        = 400
open_files_limit        = 1000
EOF
) | sudo tee /etc/my.cnf

log "Created /etc/my.cnf file with optimized MySQL configuration."
echo ""
log "Further optimization can be made by running mysql-tunner."
sleep 2

# Restart MySQL to apply changes
sudo systemctl restart mysqld
echo ""
log "Applied MySQL Changes and restarted MSQL Service."
echo ""
sleep 2
log "=========== Installing LetsEncrypt SSL plugin for cPanel =========="
echo ""
log "You can always change SSL Provider from Lets Encrypt to Sectigo from WHM => AutoSSL Option"
echo ""
sleep 2

# This will install, configure and set LetsEncrypt SSL Provider as default SSL Installer for cPanel Server. 
# Customer can always change the SSL Provider from AutoSSL from WHM.
/usr/local/cpanel/scripts/install_lets_encrypt_autossl_provider ;
echo ""
sleep 1
echo ""
log "Setting up default SSL Provider to LetsEncrypt for faster SSL issuances for websites"
sleep 2
echo ""
whmapi1 set_autossl_provider provider=LetsEncrypt x_terms_of_service_accepted https://letsencrypt.org/documents/LE-SA-v1.3-September-21-2022.pdf ;
echo ""
sleep 1
echo ""
echo ""
log "###########################################################################"
log "#####                                                                 #####"
log "########## Server Setup & Configuration is completed! Continuing ##########"
log "#####                                                                 #####"
log "###########################################################################"
sleep 1
echo ""
log "### ========== ### Starting Server Security & Hardening process! ### ========== ###"
echo ""

# Enabling Symlink Race Condition Protection.
echo ""
log "Enabling Symlink Race Condition Protection in Apache Configuration." 
log "This setting can be managed from WHM » Home » Service Configuration » Apache Configuration » Global Configuration as well."
sleep 1
sed -i 's/SymlinkProtect Off/SymlinkProtect On/' /etc/apache2/conf/httpd.conf && /scripts/rebuildhttpdconf && /scripts/restartsrv_httpd ;
sleep 2
echo ""
log "========== Installing Mod_Security OWASP Ruleset =========="

# This will install the OWASP ModSecurity Rules for Server Hardening. 
yes | yum install ea-modsec2-rules-owasp-crs -y ;
echo ""
log "Installed and enabled OWASP ModSecurity rules in Server Mod Security."
echo ""
sleep 1
log "========== Installing CSF Firewall & Configuring it! =========="
echo ""

# This will install and configure the CSF Firewall for better server security, it will also change SSH Port and will update in Server Firewall.
# SSH Port will also be changed in SSHD Configuration of Server and will be provided at end of the installation.
sleep 2
cd /usr/src ;
rm -fv csf.tgz ;
wget https://download.configserver.com/csf.tgz ;
tar -xzf csf.tgz ;
cd csf ;
sh install.sh ;
perl -pi -e 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf ;
log "Set CSF to live mode by disabling testing."
perl -pi -e 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "2"/g' /etc/csf/csf.conf ;
log "Restricted syslog/rsyslog access to RESTRICT_SYSLOG_GROUP."
perl -pi -e 's/TCP_IN = ".*"/TCP_IN = "20,21,22,25,26,53,80,110,143,443,465,587,993,995,2077,2078,2082,2083,2086,2087,2095,2096,30000:30100,7080,49152:65534"/g' /etc/csf/csf.conf ;
log "Opened specified TCP ports for incoming traffic."
perl -pi -e 's/TCP_OUT = ".*"/TCP_OUT = "20,21,22,25,43,53,80,113,443,873,2087,2089,2200,2703"/g' /etc/csf/csf.conf ;
log "Allowed outgoing connections on specified TCP ports."
perl -pi -e 's/UDP_IN = ".*"/UDP_IN = "20,21,53"/g' /etc/csf/csf.conf ;
log "Opened specified UDP ports for incoming traffic."
perl -pi -e 's/UDP_OUT = ".*"/UDP_OUT = "20,21,53,113,123,873,6277"/g' /etc/csf/csf.conf ;
log "Allowed outgoing connections on specified UDP ports."
perl -pi -e 's/ICMP_IN_RATE = ".*"/ICMP_IN_RATE = "50/s"/g' /etc/csf/csf.conf ;
log "Set ICMP rate limit to 50 per second."
perl -pi -e 's/USE_CONNTRACK = ".*"/USE_CONNTRACK = "0"/g' /etc/csf/csf.conf ;
log "Disabled connection tracking for performance optimization."
perl -pi -e 's/SYSLOG_CHECK = ".*"/SYSLOG_CHECK = "3600"/g' /etc/csf/csf.conf ;
log "Set syslog check interval to every hour."
perl -pi -e 's/RELAYHOSTS = ".*"/RELAYHOSTS = "1"/g' /etc/csf/csf.conf ;
log "Enabled or configured relay hosts settings."
perl -pi -e 's/VERBOSE = ".*"/VERBOSE = "0"/g' /etc/csf/csf.conf ;
log "Reduced verbosity of CSF logging."
perl -pi -e 's/DROP_NOLOG = ".*"/DROP_NOLOG = "67,68,111,113,135:139,445,500,513,520,585"/g' /etc/csf/csf.conf ;
log "Set certain packets to be dropped without logging to reduce log noise."
perl -pi -e 's/LF_PERMBLOCK_ALERT = ".*"/LF_PERMBLOCK_ALERT = "0"/g' /etc/csf/csf.conf ;
log "Disabled email alerts for permanent IP blocks."
perl -pi -e 's/LF_NETBLOCK_ALERT = ".*"/LF_NETBLOCK_ALERT = "0"/g' /etc/csf/csf.conf ;
log "Disabled email alerts for network-wide blocks."
perl -pi -e 's/CC_INTERVAL = ".*"/CC_INTERVAL = "7"/g' /etc/csf/csf.conf ;
log "Set country code update interval to 7 days."
perl -pi -e 's/LF_EMAIL_ALERT = ".*"/LF_EMAIL_ALERT = "0"/g' /etc/csf/csf.conf ;
log "Disabled email alerts for login failures."
perl -pi -e 's/SAFECHAINUPDATE = "0"/SAFECHAINUPDATE = "1"/g' /etc/csf/csf.conf ;
log "Enabled safe chain updates for CSF."
perl -pi -e 's/LF_SSHD_PERM = "1"/LF_SSHD_PERM = "3600"/g' /etc/csf/csf.conf ;
log "Configured SSHD permanent block time to 3600 seconds."
perl -pi -e 's/LF_FTPD_PERM = "1"/LF_FTPD_PERM = "3600"/g' /etc/csf/csf.conf ;
log "Configured FTPD permanent block time to 3600 seconds."
perl -pi -e 's/LF_CPANEL_PERM ="1"/LF_CPANEL_PERM = "1800"/g' /etc/csf/csf.conf ;
log "Set cPanel permanent block time to 1800 seconds after repeated login failures."
perl -pi -e 's/LF_SMTPAUTH_PERM = "1"/LF_SMTPAUTH_PERM = "1800"/g' /etc/csf/csf.conf ;
log "Set SMTP Auth permanent block time to 1800 seconds after repeated login failures."
perl -pi -e 's/LF_POP3D_PERM = "1"/LF_POP3D_PERM = "1800"/g' /etc/csf/csf.conf ;
log "Set POP3 permanent block time to 1800 seconds after repeated login failures."
perl -pi -e 's/LF_IMAPD_PERM = "1"/LF_IMAPD_PERM = "1800"/g' /etc/csf/csf.conf ;
log "Set IMAP permanent block time to 1800 seconds after repeated login failures."
perl -pi -e 's/LF_HTACCESS_PERM = "1"/LF_HTACCESS_PERM = "1800"/g' /etc/csf/csf.conf ;
log "Set HTACCESS permanent block time to 1800 seconds after repeated login failures."
perl -pi -e 's/LF_MODSEC_PERM = "1"/LF_MODSEC_PERM = "1800"/g' /etc/csf/csf.conf ;
log "Set ModSecurity permanent block time to 1800 seconds after repeated triggers."
CURRENTPORTNUM=22
NEWPORTNUM=$(( $RANDOM % 500  + 1500 ))
TCPIN=$(cat /etc/csf/csf.conf | grep ^TCP_IN)
TCPINNEW=$(cat /etc/csf/csf.conf | grep ^TCP_IN | sed -e "s/,${CURRENTPORTNUM},/,${NEWPORTNUM},/")
sed -i "s/$TCPIN/$TCPINNEW/g" /etc/csf/csf.conf
csf -r ;
perl -pi -e "s/#Port 22/Port $NEWPORTNUM/g" /etc/ssh/sshd_config ;
systemctl restart sshd ;
log "Changed SSH Port to $NEWPORTNUM in CSF Firewall and in sshd_config."
log "CSF Firewall is installed and configured"
sleep 1
echo ""
sleep 1
clear ;
sleep 1
log "========== Installing ImunifyAV Free version and configuring it! =========="
sleep 1
echo ""
cd /root/; wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh ;
bash imav-deploy.sh ;
log "Please wait!"
echo ""
sed -i -e "s|cpu: .*|cpu: 1|" -e "s|io: .*|io: 1|" /etc/sysconfig/imunify360/imunify360.config #Set CPU/IO for malware scans ;
systemctl restart imunify-antivirus ;
/usr/share/av-userside-plugin.sh ;
echo ""
log "Installed and configured ImunifyAV Free version."
sleep 1
clear ;
sleep 1
log "========== Running further security configurations, please wait! =========="

# This will disable the compilers and will perform further Security hardening of the Server. 
echo ""
sleep 2
/scripts/compilers off ;
/scripts/smtpmailgidonly off ;
perl -I/usr/local/cpanel -MCpanel::LoginProfile -le 'print [Cpanel::LoginProfile::install_profile('limits')]->[1];' ;
systemctl stop rpcbind ;
systemctl disable rpcbind ;
log "Disabled compilers, RPCBIND and Enabled Shell Fork Bomb Protection"
sleep 2
log "========== Disabling cpHulk to avoid False-Positives=========="
whmapi1 configureservice service=cphulkd enabled=0 monitored=0 ;
/usr/local/cpanel/etc/init/stopcphulkd ;
/usr/local/cpanel/bin/cphulk_pam_ctl --disable ;
log "Stopped and Disabled CPHulk Service"
sleep 1
echo ""
whmapi1 configurebackgroundprocesskiller processes_to_kill='BitchX' processes_to_kill-1='bnc' processes_to_kill-2='eggdrop' processes_to_kill-3='generic-sniffers' processes_to_kill-4='guardservices' processes_to_kill-5='ircd' processes_to_kill-6='psyBNC' processes_to_kill-7='ptlink' processes_to_kill-8='services' ;
systemctl restart cpanel ;
log "Disabled Background Process Killer"
log "BitchX"
log "bnc"
log "eggdrop"
log "generic-sniffers"
log "guardservices"
log "ircd"
log "psyBNC"
log "ptlink"
log "services"
log ""
sleep 2
echo ""
log "Done, continuing..."
echo ""
log "========== Enabling Monitoring for all Services =========="
whmapi1 enable_monitor_all_enabled_services ;
sleep 2
log "Done, continuing..."
clear ;
echo ""
log "##### ========== Configuring Tweak Settings, please wait! ========== #####"

# This will configure and optimize the Tweak Settings of the Server. 
echo ""
sleep 2
echo ""
echo "....."
sleep 1
echo "...."
sleep 1
echo "..."
sleep 1
echo ".."
sleep 2
echo "."
sleep 2
echo ""
whmapi1 set_tweaksetting key=phploader value=sourceguardian,ioncube ;
log "Enabled SourceGuardian and IonCube loaders."
whmapi1 set_tweaksetting key=php_upload_max_filesize value=512 ;
log "Set PHP upload max filesize to 512MB."
whmapi1 set_tweaksetting key=skipboxtrapper value=1 ;
log "Disabled BoxTrapper spam trap."
whmapi1 set_tweaksetting key=resetpass value=0 ;
log "Disabled password reset for cPanel accounts."
whmapi1 set_tweaksetting key=resetpass_sub value=0 ;
log "Disabled Subaccount password reset."
whmapi1 set_tweaksetting key=referrerblanksafety value=1 ;
log "Enabled blank referrer safety check."
whmapi1 set_tweaksetting key=referrersafety value=1 ;
log "Enabled referrer safety check."
whmapi1 set_tweaksetting key=cgihidepass value=1 ;
log "Enabled CGI script password hiding in logs."
whmapi1 set_tweaksetting key=maxemailsperhour value=200 ;
log "Set maximum number of emails per hour to 200."
echo ""
sleep 2
log "Tweak Settings are configured for Proper Server Security!"
echo ""
sleep 1
echo ""
log "========== Installing and configuring Redis for cPanel =========="
dnf -y install elinks ;
dnf -y install redis ;
systemctl enable redis ;
systemctl start redis ;
yes "no" | /opt/cpanel/ea-php74/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
yes "no" | /opt/cpanel/ea-php80/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
yes "no" | /opt/cpanel/ea-php81/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
yes "no" | /opt/cpanel/ea-php82/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
echo ""
log "Installed, Enabled and Configured Redis for PHP 7.4, PHP 8.0, PHP 8.1 and PHP 8.2 versions."
sleep1
echo ""
log "-- Done .. .. Continuing..."
echo ""
log "========== Installing ConfigServer Mail Queue & ConfigServer ModSecurity Control =========="
echo ""

# This will install ModSecurity Control panel and ConfigServer Mail Queue Manager for the Server.
cd /usr/src ;
rm -fv /usr/src/cmq.tgz ;
wget http://download.configserver.com/cmq.tgz ;
tar -xzf cmq.tgz ;
cd cmq ;
sh install.sh ;
rm -Rfv /usr/src/cmq* ;
echo ""
log "Installed and Activated ConfigServer Mail Queue Plugin."
sleep 2
echo ""
cd /usr/src ;
rm -fv /usr/src/cmc.tgz ;
wget http://download.configserver.com/cmc.tgz ;
tar -xzf cmc.tgz ;
cd cmc ;
sh install.sh ;
rm -Rfv /usr/src/cmc* ;
log "Installed and Activated ConfigServer Mod Security Control Plugin."
echo ""
sleep 2
log "We are Done!"
sleep 2
clear ;
log "###############################################################################"
log "#                                                                             #"
log "#            Server Configuration & Harening is completed! Continuing         #"
log "#                                                                             #"
log "###############################################################################"
echo ""
sleep 2
clear ;
log "##############################################################################################################"
log "#                                                                                                            #"
log "#               Your Server IP is: $serverip & SSH Port is the $NEWPORTNUM,                                 #"
log "#                         WHM URL is: https://$serverip:2087                                               #"
log "#                                                                                                            #"
log "#      Please ignore the Selfsigned SSL Error, you can use your Server Root Password for login to WHM        #"
log "#                                                                                                            #"
log "#      All the details are logged in /root/panelbot-serversetup.log file including your SSH Port Number.     #"
log "#                                                                                                            #"
log "#      No configuration is required, all the settings are configured and server is secured as well.          #"
log "#      Thank you for using this Script. If you liked this Script, please do not forget to Donate!            #"
log "#                                                                                                            #"
log "#      You can donate via https://www.ahtshamjutt.com , Also make sure to spread the word!                   #"
log "#                                                                                                            #"
log "##############################################################################################################"
echo ""
echo ""
sleep 5
echo ""

# This script will provide all the details on new SSH Login about Last Login, Previous Failed Login Attempts, Server Load, Disk Usage and RAM usage etc.

perl -pi -e "s/#PrintMotd yes/PrintMotd no/g" /etc/ssh/sshd_config ;
echo ""
systemctl restart sshd ;
chmod +x /root/easycpanel/login-info.sh ;
cp /root/easycpanel/login-info.sh /etc/profile.d/ ;
echo ""
echo ""

# Cleaning up Files.
log "Cleaning up Files!"
rm -rf /root/easycpanel ;
log "Finalized Installation Process!"
sleep 1
time=$(date)
log "Script Completed at $time."
log "Thank you for using this Script. You can always contrinbute by any Means."
sleep 2
log "A reboot is required, please note down the above information and type reboot then press enter."

# Thank you for using this script, you can always contribute by any means. 

#####