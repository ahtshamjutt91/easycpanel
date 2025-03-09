#!/bin/bash
# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Clear the screen for a clean look
clear

# Display a compact banner
echo -e "${BLUE}┌────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│${GREEN}        cPanel Configuration, Hardening & Security      ${BLUE}│${NC}"
echo -e "${BLUE}│${YELLOW}              Created by Ahtsham Jutt                   ${BLUE}│${NC}"
echo -e "${BLUE}│${WHITE}       Website: ahtshamjutt.com | me@ahtshamjutt.com     ${BLUE}│${NC}"
echo -e "${BLUE}│${CYAN}       Support: ${WHITE}https://ko-fi.com/ahtshamjutt ${CYAN}☕         ${BLUE}│${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────┘${NC}"

# Pause to read the header
sleep 2

# Instruction message
echo -e "\n${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${WHITE}           Select the Option to Optimize your cPanel Server:     ${CYAN}│${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"

# Details about options with better visibility
echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│${WHITE}                      IMPORTANT OPTIONS                         ${YELLOW}│${NC}"
echo -e "${YELLOW}├─────────────────────────────────────────────────────────────────┤${NC}"
echo -e "${YELLOW}│${GREEN} Option 1: ${WHITE}Apache Web Server with MPM Event and PHP-FPM        ${YELLOW}│${NC}"
echo -e "${YELLOW}│         ${WHITE}• Optimizes Apache with MPM Event                       ${YELLOW}│${NC}"
echo -e "${YELLOW}│         ${WHITE}• Configures PHP-FPM for better performance             ${YELLOW}│${NC}"
echo -e "${YELLOW}│         ${WHITE}• Ideal for most standard cPanel setups                 ${YELLOW}│${NC}"
echo -e "${YELLOW}│                                                                 ${YELLOW}│${NC}"
echo -e "${YELLOW}│${GREEN} Option 2: ${WHITE}NGinx as Reverse Proxy with Apache & PHP-FPM        ${YELLOW}│${NC}"
echo -e "${YELLOW}│         ${WHITE}• Installs Engintron (NGinx reverse proxy)              ${YELLOW}│${NC}"
echo -e "${YELLOW}│         ${WHITE}• Keeps Apache as backend with PHP-FPM                  ${YELLOW}│${NC}"
echo -e "${YELLOW}│         ${WHITE}• Better for high-traffic websites                      ${YELLOW}│${NC}"
echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────┘${NC}"

# Pause to read the options
sleep 3

# Options loop with better UI
while true; do
  echo -e "\n${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│${WHITE}                          Choose an Option:                      ${CYAN}│${NC}"
  echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
  echo -e "\n${GREEN}1.${NC} Optimize cPanel with ${GREEN}Apache Web Server${NC} (MPM Event + PHP-FPM)"
  echo -e "${GREEN}2.${NC} Optimize cPanel with ${GREEN}NGinx Reverse Proxy${NC} (Engintron + Apache + PHP-FPM)"
  
  # Get user choice with better prompt
  echo -e "\n${YELLOW}Enter your choice (1 or 2):${NC}"
  read -p "▶ " choice
  
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