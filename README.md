# EasycPanel (1 Click cPanel Server Security & Optimization Script)


## Description: 
If you are a new cPanel user, an experienced Linux System Admin or Web Hosting provider who offers cPanel Servers and want to save time, this script is for you. 
This Bash Script can install, configure, optimize  cPanel and solidify the server security. Just run this script on a AlmaLinux Server and this Script will take care the rest of cPanel Server Tasks.

## Requirements:

#### OS Requirements: 
AmlaLinux OS 8 64bit, CloudLinux 6, 7 or 8 64bit (CentOS 7 Not Recommended)

#### Server Requirements: 
- VPS or Dedicated Server with Minimum 2GB RAM, Recommended 4GB RAM. 
- Minimum Disk Space 20GB, Recommended 40GB.
- Blank Server Recommended, However you can run this script on current active server to optimize and secure it.

#### License:
cPanel License Recommended (Script can run without license as well). CloudLinux License required if running CL OS. 

## Installation: 
Login to your Linux Server with root user and run the following command. Provide your Main Domain (for nameservers and hostname) and Email for Server Notifications.

To run the Script locally, please clone the repositry and then run the following command, 

````
cd easycpanel && chmod +x cPanel-v3.sh && sh cPanel-v3.sh
````
If you want to run the script directly on the Server with single command, please copy the following command and paste in your Server SSH. 
````
curl -O https://ahtshamjutt.com/cpanel-script/cPanel-v3.sh && chmod +x cPanel-v3.sh && sh cPanel-v3.sh
````

## License: 
Freeware

## **Whats New in EasycPanel V3 version?**
We've supercharged EasycPanel v3 with a host of exciting updates and enhancements, focusing on performance optimization and security. Here's what you can expect in this latest version:

    Nginx and Apache Web Servers - Now with MPM-Event and HTTP/2: We've dialed up the efficiency of both Nginx and Apache, integrating highly optimized MPM-Event and HTTP/2 support. This means faster, more responsive web services for your users.

    MySQL / MariaDB Basic Optimization: We've tinkered under the hood of MySQL and MariaDB, adding basic optimization to improve performance without sacrificing stability.

    Stepped-Up Server Security: Your security is paramount. That's why we've enhanced server security protocols to keep your data safer than ever.

    Configured CSF Firewall - More Options, More Security: We've supercharged the CSF Firewall, adding a plethora of options to boost both website and server security.

    Cloudflare Support for Nginx / Engintron: For sites using Cloudflare, we've enabled support by default in Nginx/Engintron, ensuring seamless integration and enhanced performance.

    Micro Caching in Nginx / Engintron - Disabled by Default: To prevent session conflicts, we've turned off micro caching in Nginx/Engintron. Your user sessions are now smoother and more reliable.

And that's just the start! EasycPanel v3 is packed with numerous other enhancements and features, all designed to make your web hosting experience smoother, safer, and more efficient.

## Detailed Description: 
This is a free-to-use Bash script that allows you to easily install cPanel, optimize it, and enhance its security with a single command. You can utilize this script on a blank server or an existing cPanel server, making it suitable for both new and experienced cPanel users.

The script handles the entire cPanel installation process, including activating the cPanel license and configuring it to run all CMS websites. It ensures the security of your cPanel server by changing the SSH port, installing a firewall, and automatically updating the firewall rules to reflect the new SSH port.

Additionally, the script takes care of installing various PHP versions, extensions, and modules. It configures all the necessary tweak settings, as well as installs and secures memcache and ImageMagick. Furthermore, it offers options to optimize or configure Apache, install or optimize nGinx, and configure and optimize it accordingly.

This script incorporates all the relevant cPanel commands documented in the cPanel Docs. The Bash file is unencrypted, freely usable, and redistributable (though credit is required).

## Author: 
Script is written by Ahtsham Jutt ( https://www.ahtshamjutt.com )
