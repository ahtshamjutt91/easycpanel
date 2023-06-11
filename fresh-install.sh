#!/bin/bash

# Display the script header, providing basic information about the script.
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Confiugration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#              (Created by Rack Genie rackgenie.net)                 #"
echo "#              Email for queries: info@rackgenie.net                 #"
echo "#                                                                    #"
echo "######################################################################"

# Pause the script for 3 seconds to allow the user to read the header
sleep 3

# Display an important notice to the user, asking them to choose between installing Apache with PHP-FPM or NGinx with suPHP PHP Handler
echo ""
echo ""
echo "######## Please Select the Option if you want to Install Apache with PHP-FPM or nGinx with suPHP PHP Handler ########"
echo ""

# Display more detailed information about what each option does
echo "########################################################################"
echo "##### THIS IS IMPORTANT, PLEASE READ CAREFULLY BEFORE SELECTING    #####"
echo "#####                                                              #####"
echo "##### First Option will Install Apache Web Server with PHP-FPM     #####"
echo "#####                                                              #####"
echo "##### Second Option will Install nGinx Web Server with suPHP       #####"
echo "########################################################################"

# Pause the script for 2 seconds to allow the user to read the options
sleep 2

# Start a loop until a valid choice is made
while true; do
  # Display the options for the user to choose from
  echo ""
  echo "Please select an option:"
  echo "1. Install Apache Web Server with PHP-FPM (Recommended)"
  echo "2. NGinx Web Server with suPHP PHP Handler"

  # Read the user's choice
  read -p "Enter your choice (1 or 2): " choice

  # Depending on the user's choice, perform the relevant action
  case $choice in
    1)
      # Option 1 selected: Install Apache Web Server with PHP-FPM
      echo "Install Apache Web Server with PHP-FPM (Recommended)"
      # Execute the Apache installation script
      chmod +x fresh-install-apache.sh && sh fresh-install-apache.sh ;
      break
      ;;
    2)
      # Option 2 selected: Install NGinx Web Server with suPHP PHP Handler
      echo "NGinx Web Server with suPHP PHP Handler"
      # Execute the NGinx installation script
      chmod +x fresh-install-nginx.sh && sh fresh-install-nginx.sh ;
      break
      ;;
    *)
      # An invalid choice was made. The loop will continue until a valid choice is made.
      echo "Invalid choice. Please choose 1 or 2."
      ;;
  esac
done
