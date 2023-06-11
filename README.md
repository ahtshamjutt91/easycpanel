# EasycPanel (1 Click cPanel Server Security & Optimization Script)


## Description: 
If you are a new cPanel user, an experienced Linux System Admin or Web Hosting provider who offers cPanel Servers and want to save time, this script is for you. 
This Bash Script can install, configure, optimize  cPanel and solidify the server security. Just run this script on a AlmaLinux Server and this Script will take care the rest of cPanel Server Tasks.

## Requirements:

#### OS Requirements: 
AmlaLinux OS 8 64bit, CloudLinux 6, 7 or 8 64bit (CentOS 7 Not Recommended)

#### Server Requirements: 
- VPS or Dedicated Server with Minimum 1GB RAM, Recommended 2GB RAM. 
- Minimum Disk Space 20GB, Recommended 40GB.
- Blank Server Recommended, However you can run this script on current active server to optimize and secure it.

#### License:
cPanel License Recommended (Script can run without license as well). CloudLinux License required if running CL OS. 

## Installation: 
Login to your Linux Server with root user and run the following command. Provide your Main Domain (for nameservers and hostname) and Email for Server Notifications.

To run the Script locally, please clone the repositry and then run the following command, 

````
cd easycpanel && chmod +x cPanel-v2.sh && sh cPanel-v2.sh
````
If you want to run the script directly on the Server with single command, please copy the following command and paste in your Server SSH. 
````
curl -O https://ahtshamjutt.com/cpanel-script/cPanel-v2.sh && chmod +x cPanel-v2.sh && sh cPanel-v2.sh
````

## License: 
Freeware

## Detailed Description: 
This is a free-to-use Bash script that allows you to easily install cPanel, optimize it, and enhance its security with a single command. You can utilize this script on a blank server or an existing cPanel server, making it suitable for both new and experienced cPanel users.

The script handles the entire cPanel installation process, including activating the cPanel license and configuring it to run all CMS websites. It ensures the security of your cPanel server by changing the SSH port, installing a firewall, and automatically updating the firewall rules to reflect the new SSH port.

Additionally, the script takes care of installing various PHP versions, extensions, and modules. It configures all the necessary tweak settings, as well as installs and secures memcache and ImageMagick. Furthermore, it offers options to optimize or configure Apache, install or optimize nGinx, and configure and optimize it accordingly.

This script incorporates all the relevant cPanel commands documented in the cPanel Docs. The Bash file is unencrypted, freely usable, and redistributable (though credit is required).

## Author: 
Script is written by Ahtsham Jutt ( https://www.ahtshamjutt.com )
