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
git clone https://github.com/ahtshamjutt91/easycpanel.git
cd easycpanel && chmod +x cPanel-v4.sh && sh cPanel-v4.sh
```

## What's New in Version 4.1

### LiteSpeed Web Server Support (New)
- **Third web server option**: Install LiteSpeed Enterprise as a drop-in Apache replacement
  (reads .htaccess natively) from the optimization menu
- **License guardrails**: Pre-flight checks compare your license tier against server RAM,
  domain and account counts before anything is installed — LiteSpeed refuses to run on
  servers that exceed the tier's RAM limit, so the script catches this up front
- **Safe rollout**: Installs alongside Apache on a port offset first so you can test, with
  one-click switchover and rollback through the WHM plugin
- **LSCache**: WordPress cache plugin deployment (with confirmation before touching customer
  sites on shared servers), HTTP/3 (QUIC) firewall configuration, WebAdmin console lockdown
  with a generated password, and OWASP ModSecurity rules carried over from Apache

### PHP Version Coverage
- **Newest stable PHP auto-install**: When cPanel publishes a new PHP version (such as
  PHP 8.5), the scripts detect and install it with the full extension set (bcmath, curl,
  gd, mbstring, memcached, mysqlnd, opcache, soap, zip and more) — skipped gracefully on
  servers where it is not yet available
- **Default PHP raised to 8.3** for new installations

### Reliability Fixes
- **MySQL/MariaDB configuration fix**: Removed the socket/pid/datadir overrides that caused
  "MySQL daemon startup failure" and broken client connections on some servers; restarts now
  use cPanel's own service manager with a health check and automatic rollback to the previous
  configuration if MySQL fails to come back up
- **Verified downloads**: All script assets download exclusively from the official project
  mirror with SHA256 checksum verification — a failed or tampered download aborts the firewall
  installation instead of silently continuing
- **Shared library (`lib.sh`)**: All common helpers now live in one file used by every script,
  so fixes apply everywhere at once; it is fetched automatically from the project mirror when
  a script is run standalone
- **Retired ConfigServer add-ons removed**: cmq/cmc (Mail Queue and ModSecurity Control
  plugins) were discontinued upstream and are no longer installed

### Performance Improvements
- **PHP-FPM pool tuning**: Pool defaults (max children, request recycling, idle timeout) are
  now computed from server RAM and your usage profile instead of cPanel's minimal defaults
- **Opcache tuning**: Right-sized opcache memory and file limits applied to every installed
  PHP version
- **Kernel tuning**: BBR congestion control (when the kernel supports it), sensible swappiness,
  transparent hugepages disabled for MySQL/MariaDB, and tuned connection queues
- **Faster runs**: Reduced pacing delays save several minutes per run

### Security Enhancements
- **cPanel license check**: Validates your license at run time, detects the license tier, and
  warns when the account count exceeds what the tier includes
- **Secured /tmp**: Mounted with noexec/nosuid via cPanel's securetmp
- **Redis hardening**: On shared servers Redis now requires a password (generated and saved
  to /root/.redis.pass) so local accounts cannot read or flush caches
- **Memcached PHP extension**: Actually installed for each PHP version (previously only the
  daemon was installed)

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

### Version 4.1 (July 2026)
- Added LiteSpeed Web Server as a third web server option with license tier pre-flight
  checks (RAM/domain/account limits), guided port-offset installation with rollback,
  LSCache deployment, HTTP/3 firewall setup and WebAdmin hardening
- Added automatic installation of the newest stable PHP version with the full extension
  set as soon as cPanel publishes it; raised the default PHP version to 8.3
- Quick-install now bootstraps all companion files automatically when only cPanel-v4.sh
  was downloaded
- Fixed MySQL/MariaDB startup failures caused by socket, pid-file and datadir overrides in
  the generated /etc/my.cnf; corrected accidental downgrades of table_open_cache and
  max_allowed_packet; restarts now health-check MySQL and roll back automatically on failure
- Fixed ImageMagick PHP extension loop that never ran due to a list-format mismatch
- Installed the memcached PHP extension per PHP version (daemon alone was previously installed)
- Added Redis password protection on shared servers (saved to /root/.redis.pass)
- Fixed SSH port change handling for both commented and uncommented Port lines, and CSF
  TCP_IN replacement at any list position
- Replaced non-existent CSF SYSCTL_* settings with a real sysctl.d configuration
- Added BBR congestion control, swappiness and transparent hugepage tuning
- Added PHP-FPM pool tuning computed from RAM and usage profile
- Added opcache tuning for all installed PHP versions
- Added /tmp hardening via cPanel securetmp
- Added cPanel license validation with tier and account-count warnings
- Added SHA256 checksum verification for mirror downloads
- Extracted all shared helpers into lib.sh (single source of truth for every script)
- Removed retired ConfigServer cmq/cmc plugins (discontinued upstream)
- Rebuilt terminal output with self-aligning boxes; rewrote the SSH login banner with a
  root-only interactive guard; reduced pacing delays for faster runs
- Added continuous linting (syntax check and ShellCheck) on every push
- Improved input validation for domain and email prompts

### Version 4.0.1 (October 2025)
- Updated CSF download mirror to resolve firewall installation issue
- Enabled CSF Messenger service for self-unblock functionality via cPanel/WHM logins

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