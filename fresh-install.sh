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

# Clear the screen for a clean look
clear

# Display a compact banner
btop "$BLUE"
bctr "$BLUE" "${GREEN}cPanel Configuration, Hardening & Security"
bctr "$BLUE" "${YELLOW}Created by Ahtsham Jutt"
bctr "$BLUE" "${WHITE}Website: ahtshamjutt.com | me@ahtshamjutt.com"
bctr "$BLUE" "${CYAN}Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕"
bbot "$BLUE"

# Pause the script for 1 second
sleep 1

# Web Server selection menu with tooltips
echo; btop "$CYAN"
bctr "$CYAN" "${WHITE}Select your preferred web server:"
bsep "$CYAN"
brow "$CYAN" " ${GREEN}1.${WHITE} Apache Web Server with PHP-FPM"
brow "$CYAN" "   ${YELLOW}↳ Best for standard hosting, highly compatible"
brow "$CYAN" ""
brow "$CYAN" " ${GREEN}2.${WHITE} NGinx as Reverse Proxy (Engintron) with PHP-FPM"
brow "$CYAN" "   ${YELLOW}↳ Better performance for high-traffic sites"
bbot "$CYAN"

# Read the user's choice
echo -e "\n${YELLOW}Enter your choice (1 or 2):${NC}"
read -rp "▶ " choice

# Start a loop until a valid choice is made
while true; do
  # Process the user's choice
  case $choice in
    1)
      echo -e "\n${GREEN}✓${NC} Option 1 selected: Installing ${WHITE}Apache Web Server${NC} with ${WHITE}PHP-FPM${NC}."
      echo -e "${YELLOW}This setup provides a good balance of performance and compatibility.${NC}"
      echo -e "${YELLOW}Executing installation script...${NC}"
      
      # Execute the Apache installation script
      chmod +x fresh-install-apache.sh && ./fresh-install-apache.sh
      break
      ;;
    2)
      echo -e "\n${GREEN}✓${NC} Option 2 selected: Installing ${WHITE}NGinx as Reverse Proxy${NC} with ${WHITE}PHP-FPM${NC}."
      echo -e "${YELLOW}This setup offers better performance for high-traffic websites.${NC}"
      echo -e "${YELLOW}Executing installation script...${NC}"
      
      # Execute the NGinx installation script
      chmod +x fresh-install-nginx.sh && ./fresh-install-nginx.sh
      break
      ;;
    *)
      echo -e "\n${RED}✗${NC} Invalid choice. Please select either ${GREEN}1${NC} or ${GREEN}2${NC}."
      echo -e "${YELLOW}Enter your choice (1 or 2):${NC}"
      read -rp "▶ " choice
      ;;
  esac
done