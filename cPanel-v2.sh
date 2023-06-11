#!/bin/bash

# Display the script header, providing basic information about the script.
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Confiugration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#               (Created by Rack Genie rackgenie.net)                #"
echo "#              Email for queries: info@rackgenie.net                 #"
echo "#                                                                    #"
echo "######################################################################"

# Pause the script for 3 seconds to allow the user to read the header
sleep 3

# Display an important notice to the user, asking them to choose between a fresh install or optimization and security setup for an existing server
echo ""
echo ""
echo "######## Please Select the Option if you want to Install cPanel on Fresh Server or Secure and Optimize the Current Active Server with Data ########"
echo ""
echo ""

# Display more detailed information about what each option does
echo "########################################################################"
echo "##### THIS IS IMPORTANT, PLEASE READ CAREFULLY BEFORE SELECTING    #####"
echo "#####                                                              #####"
echo "##### First Option will Install OS on Fresh Server with AlmaLinux  #####"
echo "#####                                                              #####"
echo "##### Second Option will Secure and Optimize Current Server        #####"
echo "##### It will also Convert all Accounts to PHP-FPM PHP handler     #####"
echo "########################################################################"

# Pause the script for 2 seconds to allow the user to read the options
sleep 2

# Display the options for the user to choose from
echo ""
echo ""
echo "Please select an option:"
echo "1. Install Fresh cPanel, Optimize and Secure it (Fresh AlmaLinux 8 OS is required)"
echo "2. Optimize and Secure my current Active cPanel Server"

# Read the user's choice
read -p "Enter your choice (1 or 2): " choice

# Depending on the user's choice, perform the relevant action
case $choice in
  1)
    # Option 1 selected: Install fresh cPanel and secure it
    echo "You selected Option 1: Install Fresh cPanel, Optimize and Secure it"
    # Execute the fresh install script
    chmod +x fresh-install.sh && sh fresh-install.sh ;
    ;;
  2)
    # Option 2 selected: Optimize and secure the current cPanel server
    echo "You selected Option 2: Optimize and Secure my current Active cPanel Server"
    # Execute the optimization script
    chmod +x optimize-cpanel.sh && sh optimize-cpanel.sh ;
    ;;
  *)
    # An invalid choice was made
    echo "Invalid choice. Please choose 1 or 2. (Don't use Num Keypad for choice!)"
    ;;
esac
