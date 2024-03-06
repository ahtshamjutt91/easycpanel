#!/bin/bash

# Clear the screen for a clean look
clear

# Display the script header
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Configuration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#               Created by Ahtsham Jutt - ahtshamjutt.com            #"
echo "#                  Email for queries: me@ahtshamjutt.com             #"
echo "#                                                                    #"
echo "######################################################################"

# Pause the script for 3 seconds to allow the user to read the header
sleep 3

# Display an important notice to the user
echo -e "\nPlease choose the desired operation:"
echo -e "1. Install cPanel on a fresh server (requires AlmaLinux 8)"
echo -e "2. Secure and optimize an existing cPanel server\n"

# Pause the script for 2 seconds to allow the user to read the options
sleep 2

# Read the user's choice
read -p "Enter your choice (1 or 2): " choice

# Depending on the user's choice, perform the relevant action
case $choice in
  1)
    echo -e "\nOption 1 selected: Installing fresh cPanel and securing it."
    # Execute the fresh install script
    chmod +x fresh-install.sh && ./fresh-install.sh
    ;;
  2)
    echo -e "\nOption 2 selected: Optimizing and securing the current cPanel server."
    # Execute the optimization script
    chmod +x optimize-cpanel.sh && ./optimize-cpanel.sh
    ;;
  *)
    echo -e "\nInvalid choice. Please select either 1 or 2."
    ;;
esac
