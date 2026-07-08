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

# Pause to read the header
sleep 2

# Instruction message
echo; btop "$CYAN"
bctr "$CYAN" "${WHITE}Select the Option to Optimize your cPanel Server:"
bbot "$CYAN"

# Details about options with better visibility
echo; btop "$YELLOW"
bctr "$YELLOW" "${WHITE}IMPORTANT OPTIONS"
bsep "$YELLOW"
brow "$YELLOW" "${GREEN} Option 1: ${WHITE}Apache Web Server with MPM Event and PHP-FPM"
bctr "$YELLOW" "${WHITE}• Optimizes Apache with MPM Event"
bctr "$YELLOW" "${WHITE}• Configures PHP-FPM for better performance"
bctr "$YELLOW" "${WHITE}• Ideal for most standard cPanel setups"
brow "$YELLOW" ""
brow "$YELLOW" "${GREEN} Option 2: ${WHITE}NGinx as Reverse Proxy with Apache & PHP-FPM"
bctr "$YELLOW" "${WHITE}• Installs Engintron (NGinx reverse proxy)"
bctr "$YELLOW" "${WHITE}• Keeps Apache as backend with PHP-FPM"
bctr "$YELLOW" "${WHITE}• Better for high-traffic websites"
bbot "$YELLOW"

# Pause to read the options
sleep 3

# Options loop with better UI
while true; do
  echo; btop "$CYAN"
  bctr "$CYAN" "${WHITE}Choose an Option:"
  bbot "$CYAN"
  echo -e "\n${GREEN}1.${NC} Optimize cPanel with ${GREEN}Apache Web Server${NC} (MPM Event + PHP-FPM)"
  echo -e "${GREEN}2.${NC} Optimize cPanel with ${GREEN}NGinx Reverse Proxy${NC} (Engintron + Apache + PHP-FPM)"
  
  # Get user choice with better prompt
  echo -e "\n${YELLOW}Enter your choice (1 or 2):${NC}"
  read -rp "▶ " choice
  
  # Action based on choice with visual feedback
  case $choice in
    1)
      echo -e "\n${GREEN}✓${NC} Selected: Optimizing cPanel with Apache & PHP-FPM"
      echo -e "${YELLOW}Executing optimization script...${NC}"
      chmod +x optimize-apache.sh && bash optimize-apache.sh
      break
      ;;
    2)
      echo -e "\n${GREEN}✓${NC} Selected: Optimizing cPanel with NGinx & Apache"
      echo -e "${YELLOW}Executing optimization script...${NC}"
      chmod +x optimize-nginx.sh && bash optimize-nginx.sh
      break
      ;;
    *)
      echo -e "\n${RED}✗${NC} Invalid choice. Please select either ${GREEN}1${NC} or ${GREEN}2${NC}."
      sleep 1
      ;;
  esac
done