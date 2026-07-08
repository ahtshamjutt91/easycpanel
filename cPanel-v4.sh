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

# Quick-install bootstrap: when only this file was downloaded, fetch the
# companion scripts and profiles from the project mirror
REQUIRED_FILES=(fresh-install.sh fresh-install-apache.sh fresh-install-nginx.sh
    optimize-cpanel.sh optimize-apache.sh optimize-nginx.sh litespeed.sh
    revert-optimization.sh login-info.sh
    event-php-fpm-almalinux8.json event-php-fpm-almalinux9.json)
for req in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$req" ]; then
        echo -e "${YELLOW}Fetching $req from the project mirror...${NC}"
        if ! wget -q -O "$SCRIPT_DIR/$req" "https://script.ahtshamjutt.com/easycpanel/$req"; then
            rm -f "$SCRIPT_DIR/$req"
            echo -e "${RED}✗${NC} Could not download $req from the project mirror."
            exit 1
        fi
    fi
done
chmod +x "$SCRIPT_DIR"/*.sh

# Clear the screen for a clean look
clear

# Check OS compatibility first
check_os_compatibility

# Display a compact banner
btop "$BLUE"
bctr "$BLUE" "${GREEN}cPanel Configuration, Hardening & Security"
bctr "$BLUE" "${YELLOW}Created by Ahtsham Jutt"
bctr "$BLUE" "${WHITE}Website: ahtshamjutt.com | me@ahtshamjutt.com"
bctr "$BLUE" "${CYAN}Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕"
bbot "$BLUE"

# Pause the script for 1 second
sleep 1

# Simplified menu for user choice
echo; btop "$CYAN"
bctr "$CYAN" "${WHITE}Please choose an option:"
bsep "$CYAN"
brow "$CYAN" " ${GREEN}1.${WHITE} Install cPanel on a fresh server ${YELLOW}(AlmaLinux 8/9)"
brow "$CYAN" " ${GREEN}2.${WHITE} Secure and optimize existing cPanel server"
bbot "$CYAN"

# Read the user's choice
echo -e "\n${YELLOW}Enter your choice (1 or 2):${NC}"
read -rp "▶ " choice

# Process the user's choice
case $choice in
  1)
    echo -e "\n${GREEN}✓${NC} Option 1 selected: Installing fresh cPanel on AlmaLinux 8/9 and securing it."
    echo -e "${YELLOW}Executing installation script...${NC}"
    chmod +x fresh-install.sh && ./fresh-install.sh
    ;;
  2)
    echo -e "\n${GREEN}✓${NC} Option 2 selected: Optimizing and securing the current cPanel server on AlmaLinux 8/9."
    echo -e "${YELLOW}Executing optimization script...${NC}"
    chmod +x optimize-cpanel.sh && ./optimize-cpanel.sh
    ;;
  *)
    echo -e "\n${RED}✗${NC} Invalid choice. Please select either ${GREEN}1${NC} or ${GREEN}2${NC}."
    ;;
esac