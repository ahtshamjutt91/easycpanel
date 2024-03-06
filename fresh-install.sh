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
echo -e "\nSelect the web server setup you wish to install:"
echo -e "1. Apache Web Server with PHP-FPM"
echo -e "2. NGinx as Reverse Proxy (Engintron) with PHP-FPM\n"

# Pause the script for 2 seconds to allow the user to read the options
sleep 2

# Start a loop until a valid choice is made
while true; do
  # Read the user's choice
  read -p "Enter your choice (1 or 2): " choice

  # Depending on the user's choice, perform the relevant action
  case $choice in
    1)
      echo -e "\nOption 1 selected: Installing Apache with PHP-FPM."
      # Execute the Apache installation script
      chmod +x fresh-install-apache.sh && ./fresh-install-apache.sh
      break
      ;;
    2)
      echo -e "\nOption 2 selected: Installing NGinx with suPHP PHP Handler."
      # Execute the NGinx installation script
      chmod +x fresh-install-nginx.sh && ./fresh-install-nginx.sh
      break
      ;;
    *)
      echo -e "\nInvalid choice. Please select either 1 or 2."
      ;;
  esac
done
