#!/bin/bash
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Configuration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#               Created by Ahtsham Jutt - ahtshamjutt.com            #"
echo "#                  Email for queries: me@ahtshamjutt.com             #"
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
log "=========== Configuring Apache Web Server for PHP-FPM =========="
sleep 2
echo ""
# Get number of CPU cores
cpu_cores=$(grep -c ^processor /proc/cpuinfo)

# Get total RAM in MB
total_ram=$(free -m | grep "Mem:" | awk '{print $2}')

# Calculate Apache settings
server_limit=$((10 * cpu_cores))
max_request_workers=$((10 * cpu_cores))
threads_per_child=25
start_servers=$((cpu_cores / 2))
min_spare_threads=$((threads_per_child * 2))
max_spare_threads=$((threads_per_child * 4))
max_connections_per_child=1000
echo ""
# Create Apache configuration
cat <<EOL > /etc/apache2/conf.d/includes/pre_main_global.conf
<IfModule event.c>
    ServerLimit $server_limit
    StartServers $start_servers
    MinSpareThreads $min_spare_threads
    MaxSpareThreads $max_spare_threads
    ThreadsPerChild $threads_per_child
    MaxRequestWorkers $max_request_workers
    MaxConnectionsPerChild $max_connections_per_child
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
-e 's/\(threadsperchild[" ]*:\)\s[0-9"]\+/\1 25/' \
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
sleep 1
echo "."
sleep 2
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
sleep 2
echo "."
sleep 2
echo ""
log "PHP 8.1 is set as default PHP version for the server"
echo ""
sleep 2
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
sleep 2
echo ""
sleep 2

# This will update the required values for all the PHP versions to run websites smoothly. 
whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php74'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php74'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php74'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php74'

whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php80'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php80'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php80'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php80'

whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php81'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php81'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php81'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php81'

whmapi1 php_ini_set_directives directive='memory_limit:256M' version='ea-php82'
whmapi1 php_ini_set_directives directive='post_max_size:512M' version='ea-php82'
whmapi1 php_ini_set_directives directive='upload_max_filesize:512M' version='ea-php82'
whmapi1 php_ini_set_directives directive='max_input_vars:10000' version='ea-php82'

whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm='1'
whmapi1 convert_all_domains_to_fpm
/scripts/restartsrv_apache_php_fpm ;
printf "php_value_open_basedir: { name: 'php_value[open_basedir]', value: \"[%% documentroot %%]:[%% homedir %%]:/var/cpanel/php/sessions/[%% ea_php_version %%]:/tmp:/var/tmp\" }\n" >> /var/cpanel/ApachePHPFPM/system_pool_defaults.yaml ;
/scripts/php_fpm_config --rebuild ;
echo ""
sleep 2
echo ""
echo "PHP values for all PHP versions are updated!"
clear 
sleep 1
echo ""
log "========== Install Memcache & Securing it =========="
sleep 2

# This will install, enable and secure Memcached for the cPanel Server.
dnf -y install memcached ;
systemctl enable memcached ;
perl -pi -e "s/OPTIONS=""/OPTIONS="-l 127.0.0.1 -U 0"/g" /etc/sysconfig/memcached ;
systemctl restart memcached ;
echo "Memcache is installed and secured, continuing"
echo ""
sleep 2
clear
log "========== Installing ImageMagick with ImageMagick PHP Extensions ==========="
sleep 2

# This will install and configure the ImageMagick for all the PHP versions installed on Server. 
echo ""
dnf config-manager --set-enabled epel ;
dnf install ImageMagick ImageMagick-devel -y ;
yes | /opt/cpanel/ea-php74/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php80/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php81/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php82/root/usr/bin/pecl install imagick ;
/scripts/restartsrv_apache_php_fpm ;
echo ""
log "Done, continuing..."
echo ""
clear
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
query_cache_limit       = 1M
# InnoDB Settings
innodb_buffer_pool_size = 1G
innodb_log_file_size    = 128M
innodb_file_per_table   = 1
innodb_thread_concurrency = 4
innodb_flush_log_at_trx_commit = 2
# Logging
log_error               = /var/log/mysql/error.log
# Connection Settings
max_connections         = 151
wait_timeout            = 180
interactive_timeout     = 180
# Table and Open Files
table_open_cache        = 400
open_files_limit        = 1000
EOF
) | sudo tee /etc/my.cnf

# Restart MySQL to apply changes
sudo systemctl restart mysqld
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
sleep 1
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
sleep 2
echo ""
log "### ========== ### Starting Server Security & Hardening process! ### ========== ###"
echo ""
log "========== Installing Mod_Security OWASP Ruleset =========="

# This will install the OWASP ModSecurity Rules for Server Hardening. 
yes | yum install ea-modsec2-rules-owasp-crs -y ;
echo ""
echo "Done, continuing..."
echo ""
sleep 2
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
perl -pi -e 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "3"/g' /etc/csf/csf.conf ;
perl -pi -e 's/SAFECHAINUPDATE = "0"/SAFECHAINUPDATE = "1"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_SSHD_PERM = "1"/LF_SSHD_PERM = "3600"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_FTPD_PERM = "1"/LF_FTPD_PERM = "3600"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_CPANEL_PERM ="1"/LF_CPANEL_PERM = "1800"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_SMTPAUTH_PERM = "1"/LF_SMTPAUTH_PERM = "1800"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_POP3D_PERM = "1"/LF_POP3D_PERM = "1800"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_IMAPD_PERM = "1"/LF_IMAPD_PERM = "1800"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_HTACCESS_PERM = "1"/LF_HTACCESS_PERM = "1800"/g' /etc/csf/csf.conf ;
perl -pi -e 's/LF_MODSEC_PERM = "1"/LF_MODSEC_PERM = "1800"/g' /etc/csf/csf.conf ;
CURRENTPORTNUM=22
NEWPORTNUM=$(( $RANDOM % 500  + 1500 ))
TCPIN=$(cat /etc/csf/csf.conf | grep ^TCP_IN)
TCPINNEW=$(cat /etc/csf/csf.conf | grep ^TCP_IN | sed -e "s/,${CURRENTPORTNUM},/,${NEWPORTNUM},/")
sed -i "s/$TCPIN/$TCPINNEW/g" /etc/csf/csf.conf
csf -r ;
perl -pi -e "s/#Port 22/Port $NEWPORTNUM/g" /etc/ssh/sshd_config ;
systemctl restart sshd ;
log "CSF Firewall is installed and configured"
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
clear ;
sleep 2
log "========== Running further security configurations, please wait! =========="

# This will disable the compilers and will perform further Security hardening of the Server. 
echo ""
sleep 2
/scripts/compilers off ;
/scripts/smtpmailgidonly off ;
perl -I/usr/local/cpanel -MCpanel::LoginProfile -le 'print [Cpanel::LoginProfile::install_profile('limits')]->[1];' ;
systemctl stop rpcbind ;
systemctl disable rpcbind ;
log "========== Disabling cpHulk to avoid False-Positives=========="
whmapi1 configureservice service=cphulkd enabled=0 monitored=0 ;
/usr/local/cpanel/etc/init/stopcphulkd ;
/usr/local/cpanel/bin/cphulk_pam_ctl --disable ;
echo ""
whmapi1 configurebackgroundprocesskiller processes_to_kill='BitchX' processes_to_kill-1='bnc' processes_to_kill-2='eggdrop' processes_to_kill-3='generic-sniffers' processes_to_kill-4='guardservices' processes_to_kill-5='ircd' processes_to_kill-6='psyBNC' processes_to_kill-7='ptlink' processes_to_kill-8='services' ;
systemctl restart cpanel ;
echo ""
log "Done, continuing..."
echo ""
log "========== Enabling Monitoring for all Services =========="
whmapi1 enable_monitor_all_enabled_services ;
sleep 2
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
sleep 1
echo "."
sleep 2
echo ""
sleep 2
whmapi1 set_tweaksetting key=phploader value=sourceguardian,ioncube ;
whmapi1 set_tweaksetting key=php_upload_max_filesize value=512 ;
whmapi1 set_tweaksetting key=skipboxtrapper value=1 ;
whmapi1 set_tweaksetting key=resetpass value=0 ;
whmapi1 set_tweaksetting key=resetpass_sub value=0 ;
whmapi1 set_tweaksetting key=referrerblanksafety value=1 ;
whmapi1 set_tweaksetting key=referrersafety value=1 ;
whmapi1 set_tweaksetting key=cgihidepass value=1 ;
whmapi1 set_tweaksetting key=maxemailsperhour value=200 ;
echo ""
log "Tweak Settings are configured for Proper Server Security!"
echo ""
sleep 2
echo ""
log "========== Installing and configuring Redis for cPanel =========="
dnf -y install elinks ;
dnf -y install redis ;
systemctl enable redis ;
systemctl start redis ;
/opt/cpanel/ea-php74/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
/opt/cpanel/ea-php80/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
/opt/cpanel/ea-php81/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
/opt/cpanel/ea-php82/root/usr/bin/pecl install --configureoptions 'enable-redis-igbinary="no" enable-redis-lzf="no" enable-redis-zstd="no"' redis ;
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
sleep 1
echo ""
cd /usr/src ;
rm -fv /usr/src/cmc.tgz ;
wget http://download.configserver.com/cmc.tgz ;
tar -xzf cmc.tgz ;
cd cmc ;
sh install.sh ;
rm -Rfv /usr/src/cmc* ;
echo ""
sleep 1
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
sleep 2
echo ""

# This script will provide all the details on new SSH Login about Last Login, Previous Failed Login Attempts, Server Load, Disk Usage and RAM usage etc.
perl -pi -e "s/#PrintMotd yes/PrintMotd no/g" /etc/ssh/sshd_config ;
echo ""
systemctl restart sshd ;
chmod +x /root/easycpanel/login-info.sh ;
cp /root/easycpanel/login-info.sh /etc/profile.d/ ;
echo ""
echo ""
log "A reboot is required, please note down the above information and type reboot then press enter."

# Thank you for using this script, you can always contribute by any means. 

#####