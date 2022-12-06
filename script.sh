#!/bin/bash
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Confiugration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#              (Opensource Script by ahtshamjutt.com)                #"
echo "#              Email for queries: me@ahtshamjutt.com                 #"
echo "#                                                                    #"
echo "######################################################################"
echo ""
sleep 2
echo ""
echo ""
echo "############ PLEASE MAKE SURE YOU HAVE ACTIVE CPANEL LICENSE FOR THIS SERVER / SERVER IP ############" 
echo ""
echo ""
sleep 2
echo ""
echo "###############################################################################################"
echo ""
echo "========== Some information is required to setup your Server configuration, nameservers and hostname =========="
sleep 2
echo ""
echo ""
echo "========== Please provide your Domain / Website URL you would like to host, Example: ahtshamjutt.com =========="
read domain
sleep 1
echo ""
echo "========== Please provide your Email Address where you would like to receive Server Alerts =========="
read email
echo ""
###
#This will Get the Server Main IP to configure in cPanel and Server.
###
serverip=$(hostname -I | awk ' {print $1}') ;
sleep 2
echo ""
echo ""
clear
echo ""
echo ""
echo ""
echo "######################################################################"
echo "#                                                                    #"
echo "#               Installing cPanel/WHM & Securing it                  #"
echo "#                                                                    #"
echo "#                     Please Sit Back & Enjoy                        #"
echo "#              This Process will take some time!                     #"
echo "#                                                                    #"
echo "######################################################################"
sleep 5
echo ""
echo ""
echo ""
clear
echo "============= Updating System Pacakges & defining required values! ============="
###
#Installing Important CentOS Linux Modules and Disabling NetworkManager as cPanel does not work with the NetworkManager being enabled.
###
sudo yum update -y ;
yum install -y nload
sudo yum install wget -y ;
systemctl stop NetworkManager ;
systemctl disable NetworkManager ;
echo ""
echo ""
echo ""
sleep 2
echo ""
echo "=========== DETECTING A CPANEL INSTALLTION, PLEASE WAIT =========="
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
###
#This Process will find the existing cPanel installation then will try to update the cPanel license key to check if License is active. 
#If cPanel License is not active, Script will ask the user to confirm if they want to continue running the script or stop it. 
###
echo ""
if grep -q 'Thank you for installing cPanel & WHM' '/var/log/cpanel-install.log' ; then
        echo "cPanel/WHM is already installed, running the Server configuration & hardening process, Please wait!" ;
else 
    echo "=========== NO CPANEL INSTALLATION DETECTED, CONTINUING WITH THE INSTALLATION ==========" ;
        cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest ;
fi
echo ""
echo "========== CPANEL IS INSTALLED, CHECKING CPANEL LICENSE STATUS =========="
echo ""
if [[ $(/usr/local/cpanel/cpkeyclt) = "Updating cPanel license...Done. Update succeeded." ]];
        then
                echo "cPanel License is active, continuing with the setup" ;
else
        echo "Your cPanel License is not active"
        echo "Without active cPanel License, multiple important modules will not be installed"
        echo "Do you want to continue with the Script without cPanel License? You can always rerun the script after activating cPanel License"
while true; do

read -p "Do you want to proceed? (y/n) " yn

case $yn in 
	[yY] ) echo ok, we will proceed;
		break;;
	[nN] ) echo exiting...;
		exit;;
	* ) echo invalid response;;
esac ;
done ;
fi
echo ""
###
#This option will reconfigure the basic configuration of cPanel and will update the main Server IP, customer Email, and Nameservers.
###
sudo touch /etc/.whostmgrft ;
sudo mv /etc/wwwacct.conf /etc/wwwacct.conf.bk ;
echo "ADDR $serverip
CONTACTEMAIL $email
CONTACTPAGER
DEFMOD jupiter
ETHDEV eth0
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
sleep 3
clear
echo ""
###
#This command will enable to Initial Disk Space Quotas for the Server.
###
echo "Enabling / Updating initial quotas!"
yes |  /scripts/initquotas ;
sleep 2
clear ;
echo ""
echo "=========== Configuring EasyApache4, installing PHP versions, PHP extensions & Apache modules! =========="
echo ""
echo "this process will take few minutes, Please wait!"
echo "....."
sleep 1
echo "...."
sleep 1
echo "..."
sleep 1
echo ".."
sleep 2
echo "."
sleep 3
echo ""
sleep 3
###
#This will download and install the custom PHP Profile with all the required PHP versions and PHP Extensions required for websites, CMS scripts and Server.
###
cp phpworker.json /etc/cpanel/ea4/profiles/custom/ ;
yes | /usr/local/bin/ea_install_profile --install /etc/cpanel/ea4/profiles/custom/phpworker.json ;
echo ""
echo ""
sleep 2
echo "EasyApache4 is configured with required Apache modules, PHP versions and PHP extensions."
echo "PHP version 7.4, PHP version 8.0 & PHP version 8.1 are installed"
echo ""
sleep 4
echo ""
###
#This will setup the Server default PHP version to PHP 7.4 version.
###
echo "Setting up default PHP Version"
whmapi1 php_set_system_default_version version=ea-php74 ;
/usr/local/cpanel/scripts/restartsrv_cpsrvd ;
echo ""
echo "..."
sleep 1
echo ".."
sleep 2
echo "."
sleep 3
echo ""
echo "PHP 7.4 is set as default PHP version for the server"
echo ""
sleep 4
clear ;
echo "========== Updating PHP memory_limit and other values, Please wait! =========="
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
sleep 2
###
#This will update the required values for all the PHP versions to run websites smoothly. 
###
perl -pi -e "s/max_execution_time = 30/max_execution_time = 300/g" /opt/cpanel/ea-php74/root/etc/php.ini ;
perl -pi -e "s/max_input_time = 60/max_input_time = -1/g" /opt/cpanel/ea-php74/root/etc/php.ini ;
perl -pi -e "s/memory_limit = 32M/memory_limit = 128M/g" /opt/cpanel/ea-php74/root/etc/php.ini ;
perl -pi -e "s/post_max_size = 8M/post_max_size = 512M/g" /opt/cpanel/ea-php74/root/etc/php.ini ;
perl -pi -e "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" /opt/cpanel/ea-php74/root/etc/php.ini ;
perl -pi -e "s/max_execution_time = 30/max_execution_time = 300/g" /opt/cpanel/ea-php80/root/etc/php.ini ;
perl -pi -e "s/max_input_time = 60/max_input_time = -1/g" /opt/cpanel/ea-php80/root/etc/php.ini ;
perl -pi -e "s/memory_limit = 32M/memory_limit = 128M/g" /opt/cpanel/ea-php80/root/etc/php.ini ;
perl -pi -e "s/post_max_size = 8M/post_max_size = 512M/g" /opt/cpanel/ea-php80/root/etc/php.ini ;
perl -pi -e "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" /opt/cpanel/ea-php80/root/etc/php.ini ;
perl -pi -e "s/max_execution_time = 30/max_execution_time = 300/g" /opt/cpanel/ea-php81/root/etc/php.ini ;
perl -pi -e "s/max_input_time = 60/max_input_time = -1/g" /opt/cpanel/ea-php81/root/etc/php.ini ;
perl -pi -e "s/memory_limit = 32M/memory_limit = 128M/g" /opt/cpanel/ea-php81/root/etc/php.ini ;
perl -pi -e "s/post_max_size = 8M/post_max_size = 512M/g" /opt/cpanel/ea-php81/root/etc/php.ini ;
perl -pi -e "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" /opt/cpanel/ea-php81/root/etc/php.ini ;
/scripts/restartsrv_apache_php_fpm ;
sleep 3
echo ""
echo "PHP values for all PHP versions are updated!"
clear 
sleep 3
echo "========== Install Memcache & Securing it =========="
sleep 2
###
#This will install, enable and secure Memcached for the cPanel Server.
###
yum -y install memcached ;
systemctl enable memcached ;
perl -pi -e "s/OPTIONS=""/OPTIONS="-l 127.0.0.1 -U 0"/g" /etc/sysconfig/memcached ;
systemctl restart memcached ;
echo "Memcache is installed and secured, continuing"
echo ""
sleep 3
clear
echo "========== Installing ImageMagick with ImageMagick PHP Extensions ==========="
sleep 3
###
#This will install and configure the ImageMagick for all the PHP versions installed on Server. 
###
echo ""
yum install ImageMagick ImageMagick-devel -y ;
yes | /opt/cpanel/ea-php74/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php80/root/usr/bin/pecl install imagick ;
yes | /opt/cpanel/ea-php81/root/usr/bin/pecl install imagick ;
echo ""
echo "Done, continuing..."
echo ""
clear
echo "=========== Installing LetsEncrypt SSL plugin for cPanel =========="
sleep 3
###
#This will install, configure and set LetsEncrypt SSL Provider as default SSL Installer for cPanel Server. 
#Customer can always change the SSL Provider from AutoSSL from WHM.
###
/usr/local/cpanel/scripts/install_lets_encrypt_autossl_provider ;
echo ""
sleep 3
echo ""
echo "Setting up default SSL Provider to LetsEncrypt for faster SSL issuances for websites"
sleep 3
echo ""
whmapi1 set_autossl_provider provider=LetsEncrypt x_terms_of_service_accepted https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf ;
echo ""
echo "LetsEncrypt is set as the default SSL Provider for the Server"
echo ""
sleep 3
clear
echo "========== Installing Engintron nGinx for cPanel & configuring / optimizing it =========="
sleep 3
echo ""
###
#This will install Engintron (nGinx Web Server with all the required configurations and optimizations) for cPanel.
#Customers can always switch to default cPanel nGinx Web Server from WHM.
###
curl -sSL https://raw.githubusercontent.com/engintron/engintron/master/engintron.sh | bash -s -- install ;
sleep 3
echo "Engintron is installed and configured"
sleep 2
echo ""
echo ""
echo "###########################################################################"
echo "#####                                                                 #####"
echo "########## Server Setup & Configuration is completed! Continuing ##########"
echo "#####                                                                 #####"
echo "###########################################################################"
sleep 3
echo ""
echo "### ========== ### Starting Server Security & Hardening process! ### ========== ###"
echo ""
echo "========== Installing Mod_Security OWASP Ruleset =========="
###
#This will install the OWASP ModSecurity Rules for Server Hardening. 
###
yes | yum install ea-modsec2-rules-owasp-crs -y ;
echo ""
echo "Done, continuing..."
echo ""
sleep 3
echo "========== Installing CSF Firewall & Configuring it! =========="
echo ""
###
#This will install and configure the CSF Firewall for better server security, it will also change SSH Port and will update in Server Firewall.
#SSH Port will also be changed in SSHD Configuration of Server and will be provided at end of the installation.
###
sleep 3
cd /usr/src ;
rm -fv csf.tgz ;
wget https://download.configserver.com/csf.tgz ;
tar -xzf csf.tgz ;
cd csf ;
sh install.sh ;
perl -pi -e 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf ;
perl -pi -e 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "3"/g' /etc/csf/csf.conf ;
CURRENTPORTNUM=22
NEWPORTNUM=$(( $RANDOM % 500  + 1500 ))
TCPIN=$(cat /etc/csf/csf.conf | grep ^TCP_IN)
TCPINNEW=$(cat /etc/csf/csf.conf | grep ^TCP_IN | sed -e "s/,${CURRENTPORTNUM},/,${NEWPORTNUM},/")
sed -i "s/$TCPIN/$TCPINNEW/g" /etc/csf/csf.conf
csf -r ;
perl -pi -e "s/#Port 22/Port $NEWPORTNUM/g" /etc/ssh/sshd_config ;
systemctl restart sshd ;
echo "CSF Firewall is installed and configured"
echo ""
sleep 3
echo "========== Running further security configurations, please wait! =========="
###
#This will disable the compilers and will perform further Security hardening of the Server. 
###
echo ""
sleep 3
/scripts/compilers off ;
/scripts/smtpmailgidonly off ;
perl -I/usr/local/cpanel -MCpanel::LoginProfile -le 'print [Cpanel::LoginProfile::install_profile('limits')]->[1];' ;
systemctl stop rpcbind ;
systemctl disable rpcbind ;
echo ""
cat >/var/cpanel/killproc.conf <<EOF
BitchX
bnc
eggdrop
generic-sniffers
guardservices
ircd
psyBNC
ptlink
services
EOF
systemctl restart cpanel ;

echo ""
echo "Done, continuing..."
echo ""
sleep 3
clear ;
echo ""
echo "##### ========== Configuring Tweak Settings, please wait! ========== #####"
###
#This will configure and optimize the Tweak Settings of the Server. 
###
echo ""
sleep 3
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
sleep 3
echo ""
sleep 3
perl -pi -e "s/phploader=/phploader=ioncube,sourceguardian/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/php_upload_max_filesize=50/php_upload_max_filesize=512/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/skipboxtrapper=0/skipboxtrapper=1/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/resetpass=1/resetpass=0/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/resetpass_sub=1/resetpass_sub=0/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/referrerblanksafety=0/referrerblanksafety=1/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/referrersafety=0/referrersafety=1/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/cgihidepass=0/cgihidepass=1/g" /var/cpanel/cpanel.config ;
perl -pi -e "s/maxemailsperhour/maxemailsperhour=200/g" /var/cpanel/cpanel.config ;
echo ""
echo "Tweak Settings are configured for Proper Server Security!"
echo ""
sleep 3
echo "========== Installing ConfigServer Mail Queue & ConfigServer ModSecurity Control =========="
echo ""
###
#This will install ModSecurity Control panel and ConfigServer Mail Queue Manager for the Server.
###
cd /usr/src ;
rm -fv /usr/src/cmq.tgz ;
wget http://download.configserver.com/cmq.tgz ;
tar -xzf cmq.tgz ;
cd cmq ;
sh install.sh ;
rm -Rfv /usr/src/cmq* ;
echo ""
sleep 2
echo ""
cd /usr/src ;
rm -fv /usr/src/cmc.tgz ;
wget http://download.configserver.com/cmc.tgz ;
tar -xzf cmc.tgz ;
cd cmc ;
sh install.sh ;
rm -Rfv /usr/src/cmc* ;
echo ""
sleep 3
echo "We are Done!"
sleep 3
clear ;
echo "###############################################################################"
echo "#                                                                             #"
echo "#            Server Configuration & Harening is completed! Continuing         #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""
sleep 4
clear ;
echo "##############################################################################################################"
echo "#                                                                                                            #"
echo "#               Your Server IP is: $serverip & SSH Port is the $NEWPORTNUM,                                 #"
echo "#                         WHM URL is: https://$serverip:2087                                               #"
echo "#                                                                                                            #"
echo "#      Please ignore the Selfsigned SSL Error, you can use your Server Root Password for login to WHM        #"
echo "#                                                                                                            #"
echo "#                                                                                                            #"
echo "#      No configuration is required, all the settings are configured and server is secured as well.          #"
echo "#      Thank you for using this Script. If you liked this Script, please do not forget to Donate!            #"
echo "#                                                                                                            #"
echo "#      You can donate via https://www.ahtshamjutt.com , Also make sure to spread the word!                   #"
echo "#                                                                                                            #"
echo "##############################################################################################################"
echo ""
echo ""
sleep 2
echo ""
#####
#####
#This script will provide all the details on new SSH Login about Last Login, Previous Failed Login Attempts, Server Load, Disk Usage and RAM usage etc.
#####
#####
perl -pi -e "s/#PrintMotd yes/PrintMotd no/g" /etc/ssh/sshd_config ;
echo ""
systemctl restart sshd ;
#cd /etc/profile.d/ ;
#curl -o login-info.sh -L https://ahtshamjutt.com/cpanel-script/login-info.sh ;
cp login-info.sh /etc/profile.d/ ;
chmod +x login-info.sh ;
echo ""
echo ""
echo "A reboot is required, please note down the above information and type reboot then press enter."
echo "System will take 5 to 10 minutes to reboot, then you can login to SSH or WHM using above availabel information."
#####
#####
#Thank you for using this script, you can always contribute by any means. 
#####
#####
