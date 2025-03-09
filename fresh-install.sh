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

# Pause the script for 1 second
sleep 1

# Web Server selection menu with tooltips
echo -e "\n${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│${WHITE}              Select your preferred web server:             ${CYAN}│${NC}"
echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
echo -e "${CYAN}│ ${GREEN}1.${WHITE} Apache Web Server with PHP-FPM                          ${CYAN}│${NC}"
echo -e "${CYAN}│   ${YELLOW}↳ Best for standard hosting, highly compatible            ${CYAN}│${NC}"
echo -e "${CYAN}│                                                             ${CYAN}│${NC}"
echo -e "${CYAN}│ ${GREEN}2.${WHITE} NGinx as Reverse Proxy (Engintron) with PHP-FPM        ${CYAN}│${NC}"
echo -e "${CYAN}│   ${YELLOW}↳ Better performance for high-traffic sites               ${CYAN}│${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"

# Read the user's choice
echo -e "\n${YELLOW}Enter your choice (1 or 2):${NC}"
read -p "▶ " choice

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
      read -p "▶ " choice
      ;;
  esac
done