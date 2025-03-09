#!/bin/bash

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Clear the screen
clear

# Get system information
HOSTNAME=`uname -n`
ROOT=`df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }'`
MEMORY1=`free -t -m | grep Total | awk '{print $3" MB";}'`
MEMORY2=`free -t -m | grep "Mem" | awk '{print $2" MB";}'`
LOAD1=`cat /proc/loadavg | awk {'print $1'}`
LOAD5=`cat /proc/loadavg | awk {'print $2'}`
LOAD15=`cat /proc/loadavg | awk {'print $3'}`
Failed=$((`lastb | wc -l` - 2)) ; > /var/log/btmp
Last5=$(last -5 root)

# Display a combined welcome banner with integrated coffee tip
echo -e "${BLUE}┌──────────────── Welcome ─────────────────────────┐${NC}"
echo -e "${BLUE}│${GREEN}                 WELCOME BACK                       ${NC}"
echo -e "${BLUE}│${WHITE}         Server setup, optimized & secured by:      ${NC}"
echo -e "${BLUE}│${YELLOW}                 ahtshamjutt.com                   ${NC}"
echo -e "${BLUE}│                                                    ${NC}"
echo -e "${BLUE}│${YELLOW}           Enjoying your optimized server?         ${NC}"
echo -e "${BLUE}│${WHITE}      ☕  ${YELLOW}Support the developer with a coffee! ${WHITE}☕   ${NC}"
echo -e "${BLUE}│${GREEN}           https://ko-fi.com/ahtshamjutt             ${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────┘${NC}"

# Display system information in a compact format
echo -e "\n${CYAN}┌─── System Information ───────────────────────────┐${NC}"
echo -e "${CYAN}│${NC} ${GREEN}Hostname:${NC}      $HOSTNAME"

# Handle multiple disk entries
echo "$ROOT" | while IFS= read -r line; do
  if [ -z "$FIRST_LINE" ]; then
    echo -e "${CYAN}│${NC} ${GREEN}Disk Usage:${NC}    $line"
    FIRST_LINE=1
  else
    echo -e "${CYAN}│${NC}               $line"
  fi
done

echo -e "${CYAN}│${NC} ${GREEN}CPU Load:${NC}      $LOAD1 (1m), $LOAD5 (5m), $LOAD15 (15m)"
echo -e "${CYAN}│${NC} ${GREEN}Memory:${NC}        $MEMORY1 / $MEMORY2"
echo -e "${CYAN}│${NC} ${GREEN}Failed Logins:${NC} $Failed since last success"
echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"

# Last 5 logins in a neat format
echo -e "${CYAN}┌─── Last 5 Root Logins ──────────────────────────┐${NC}"
echo -e "${CYAN}│${NC}"
echo "$Last5" | while IFS= read -r line; do echo -e "${CYAN}│${NC} $line"; done
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────┘${NC}"