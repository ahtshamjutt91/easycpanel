#!/bin/bash
# MOTD: server status at SSH login — installed to /etc/profile.d/ by EasyCPanel

# Only for interactive root shells (sourced by /etc/profile)
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac
[ "$(id -u)" -eq 0 ] || return 0 2>/dev/null

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ── Box-drawing helpers (runtime auto-alignment) ──────────────────────
BOXW=71  # inner box width
_bord() { local b; printf -v b '%*s' "$BOXW" ''; printf '%b%s%s%s%b\n' "$1" "$2" "${b// /─}" "$3" "$NC"; }
btop() { _bord "${1:-$BLUE}" '┌' '┐'; }
bsep() { _bord "${1:-$BLUE}" '├' '┤'; }
bbot() { _bord "${1:-$BLUE}" '└' '┘'; }
brow() {
    local raw plain pad
    raw=$(printf '%b' "$2")
    plain=$(printf '%s' "$raw" | sed $'s/\x1b\\[[0-9;]*m//g')
    plain="$plain${plain//[^☕]/}"  # ☕ renders 2 cols wide
    pad=$(( BOXW - ${#plain} ))
    (( pad < 0 )) && pad=0
    printf '%b│%b%s%*s%b│%b\n' "$1" "$NC" "$raw" "$pad" '' "$1" "$NC"
}
bctr() {
    local raw plain lead
    raw=$(printf '%b' "$2")
    plain=$(printf '%s' "$raw" | sed $'s/\x1b\\[[0-9;]*m//g')
    plain="$plain${plain//[^☕]/}"  # ☕ renders 2 cols wide
    lead=$(( (BOXW - ${#plain}) / 2 ))
    (( lead < 0 )) && lead=0
    printf -v raw '%*s%s' "$lead" '' "$raw"
    brow "$1" "$raw"
}

clear

# Gather system information
HOSTNAME=$(uname -n)
DISKS=$(df -H | grep -vE '^Filesystem|tmpfs|cdrom|overlay' | awk '{print $5 " used on " $1}')
MEM_USED=$(free -m | awk '/^Mem/ {print $3}')
MEM_TOTAL=$(free -m | awk '/^Mem/ {print $2}')
read -r LOAD1 LOAD5 LOAD15 _ < /proc/loadavg
FAILED=$(( $(lastb 2>/dev/null | wc -l) - 2 ))
(( FAILED < 0 )) && FAILED=0
: > /var/log/btmp
LAST5=$(last -5 root 2>/dev/null | head -5)

# Welcome banner
btop "$BLUE"
bctr "$BLUE" "${GREEN}WELCOME BACK"
bctr "$BLUE" "${WHITE}Server setup, optimized & secured by ${YELLOW}ahtshamjutt.com"
bsep "$BLUE"
bctr "$BLUE" "${YELLOW}Enjoying your optimized server?"
bctr "$BLUE" "${WHITE}Support the developer: ${GREEN}https://ko-fi.com/ahtshamjutt ${WHITE}☕"
bbot "$BLUE"

# System information
btop "$CYAN"
bctr "$CYAN" "${WHITE}SYSTEM INFORMATION"
bsep "$CYAN"
brow "$CYAN" " ${GREEN}Hostname:${NC}      $HOSTNAME"
FIRST=1
while IFS= read -r line; do
    if [ "$FIRST" = "1" ]; then
        brow "$CYAN" " ${GREEN}Disk Usage:${NC}    $line"
        FIRST=0
    else
        brow "$CYAN" "                $line"
    fi
done <<< "$DISKS"
brow "$CYAN" " ${GREEN}CPU Load:${NC}      $LOAD1 (1m), $LOAD5 (5m), $LOAD15 (15m)"
brow "$CYAN" " ${GREEN}Memory:${NC}        ${MEM_USED} MB used / ${MEM_TOTAL} MB total"
FCOLOR=$GREEN; (( FAILED > 0 )) && FCOLOR=$RED
brow "$CYAN" " ${GREEN}Failed Logins:${NC} ${FCOLOR}$FAILED${NC} since last check"
bbot "$CYAN"

# Last 5 root logins
btop "$CYAN"
bctr "$CYAN" "${WHITE}LAST 5 ROOT LOGINS"
bsep "$CYAN"
while IFS= read -r line; do
    [ -n "$line" ] && brow "$CYAN" " $line"
done <<< "$LAST5"
bbot "$CYAN"
