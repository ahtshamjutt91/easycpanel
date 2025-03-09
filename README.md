# EasycPanel v4 - The Ultimate cPanel Server Management Solution

![EasycPanel Banner](https://ahtshamjutt.com/cpanel-script/easycpanel-banner.png)

## Overview
EasycPanel is the ultimate, free, one-click solution for installing, configuring, optimizing, and securing cPanel servers. Perfect for both novice and experienced system administrators, this powerful script handles everything from initial setup to performance tuning and security hardening.

## Why Choose EasycPanel?
- **Save Time**: Complete setup in minutes, not hours
- **Optimize Performance**: Pre-configured for maximum efficiency
- **Enhance Security**: Robust security measures implemented automatically
- **Flexibility**: Works on fresh servers or existing installations
- **Revertible**: Comprehensive backup and reversion capabilities

## Requirements

### Operating System
- AlmaLinux 8/9 (64-bit) - **Recommended**
- CloudLinux 8/9 (64-bit)

### Hardware
- **Minimum**: 2GB RAM, 20GB Disk Space
- **Recommended**: 4GB+ RAM, 40GB+ Disk Space

### Licensing
- cPanel License (recommended but not required)
- CloudLinux License (if using CloudLinux OS)

## Installation

### Quick Install
Run this single command on your server:

```bash
curl -O https://ahtshamjutt.com/cpanel-script/cPanel-v4.sh && chmod +x cPanel-v4.sh && sh cPanel-v4.sh
```

### From Repository
Clone and run:

```bash
git clone https://github.com/ahtshamjutt/easycpanel.git
cd easycpanel && chmod +x cPanel-v4.sh && sh cPanel-v4.sh
```

## What's New in Version 4

### Web Server Enhancements
- **Dual Server Optimization**: Choose between Apache-only or Nginx+Apache stack
- **Apache Optimization**: MPM-Event with HTTP/2 and dynamic resource allocation
- **Nginx Integration**: Engintron with advanced caching and Cloudflare compatibility
- **Server-Specific Tuning**: Automatically adjusts settings based on your hardware

### Performance Improvements
- **Resource-Aware Configuration**: Adjusts resource allocation based on server usage type
- **Dynamic MySQL Tuning**: Optimizes database performance based on available RAM
- **PHP-FPM Optimization**: Enhanced PHP performance with optimized settings
- **Redis Integration**: Improved caching and session handling

### Security Enhancements
- **Advanced CSF Configuration**: Comprehensive firewall with DDoS protection
- **ModSecurity with OWASP Rules**: Enterprise-grade web application firewall
- **ImunifyAV Integration**: Malware scanning and protection
- **Comprehensive Hardening**: Symlink protection, compiler restrictions, and more

### CMS Optimizations
- **WordPress-Specific Rules**: Performance tweaks for WordPress sites
- **Media Caching**: Optimized handling of static files
- **Browser Caching**: Improved client-side caching for faster repeat visits

### System Management
- **Backup System**: Comprehensive backup of all configurations
- **Reversion Capability**: Easy rollback to previous state if needed
- **SSH Security**: Automated SSH hardening with custom port options
- **Service Monitoring**: Enhanced monitoring of critical services

## Usage Options

### Fresh Installation
Use EasycPanel to set up a new cPanel server from scratch with optimal configuration.

### Server Optimization
Run on an existing server to optimize and secure it without reinstallation.

### Configuration Reversion
Use the included reversion script to roll back changes if needed:

```bash
bash revert-optimization.sh
```

## License
Free to use and redistribute with attribution.

## About the Author
Created by [Ahtsham Jutt](https://www.ahtshamjutt.com)

## ☕ Support EasycPanel Development

**EasycPanel saves you hours of work - consider buying me a coffee to keep this project alive!**

If EasycPanel has helped you, please consider supporting ongoing development and improvements. Your support directly enables new features, optimizations, and regular updates.

**[☕ Buy Me a Coffee](https://ko-fi.com/ahtshamjutt)**

*Monthly supporters get priority support and early access to new features!*

---

## Detailed Changelog

### Version 4.0 (March 2025)
- Added adaptive resource allocation based on server type (personal/shared hosting)
- Implemented comprehensive backup and restoration system
- Added WordPress-specific optimizations
- Enhanced Cloudflare integration
- Improved DDoS protection in CSF firewall
- Added better media and static file caching
- Implemented Redis for improved caching

### Version 3.0 (November 2023)
- Added Nginx and Apache optimization with MPM-Event and HTTP/2
- Implemented MySQL/MariaDB basic optimization
- Enhanced server security protocols
- Configured CSF Firewall with additional options
- Added Cloudflare support for Nginx/Engintron
- Disabled micro caching in Nginx/Engintron by default to prevent session conflicts

### Version 2.0 (March 2023)
- Added PHP 8.1 and 8.2 support
- Implemented improved security measures
- Enhanced cPanel configuration options
- Added more comprehensive logging

### Version 1.0 (January 2022)
- Initial release with basic cPanel installation and configuration
- Basic security hardening
- PHP optimization
- Apache configuration

---

*EasycPanel is a community-driven project designed to make server management accessible to everyone. Your feedback and contributions help make it better!*