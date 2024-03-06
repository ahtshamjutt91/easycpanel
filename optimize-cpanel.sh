#!/bin/bash

# Main banner
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Configuration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#               Created by Ahtsham Jutt - ahtshamjutt.com            #"
echo "#                  Email for queries: me@ahtshamjutt.com             #"
echo "#                                                                    #"
echo "######################################################################"

# Pause to read the header
sleep 3

# Instruction message
echo -e "\n\nSelect the Option to Optimize your cPanel Server:"
echo ""

# Details about options
echo "############################################################################"
echo "# IMPORTANT: READ CAREFULLY BEFORE SELECTING                               #"
echo "# Option 1: Apache Web Server with MPM Event and PHP-FPM                   #"
echo "# Option 2: NGinx as Reverse Proxy (Engintron) with MPM Event and PHP-FPM  #"
echo "############################################################################"

# Pause to read the options
sleep 2

# Options loop
while true; do
  echo -e "\nOptions:"
  echo "1. Optimize cPanel with Apache Web Server with MPM Event and PHP-FPM"
  echo "2. Optimize cPanel with NGinx as Reverse Proxy (Engintron) with MPM Event and PHP-FPM"

  # Get user choice
  read -p "Enter your choice (1 or 2): " choice

  # Action based on choice
  case $choice in
    1)
      echo "Optimizing cPanel with Apache & PHP-FPM..."
      chmod +x optimize-apache.sh && sh optimize-apache.sh
      break
      ;;
    2)
      echo "Optimizing cPanel with NGinx & suPHP..."
      chmod +x optimize-nginx.sh && sh optimize-nginx.sh
      break
      ;;
    *)
      echo "Invalid choice. Please choose 1 or 2."
      ;;
  esac
done
