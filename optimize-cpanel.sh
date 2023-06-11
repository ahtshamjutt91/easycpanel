#!/bin/bash

# Display a header message with information about the script
echo "######################################################################"
echo "#                                                                    #"
echo "#         cPanel Configuration, Hardening & Security Script          #"
echo "#                                                                    #"
echo "#              (Created by Rack Genie rackgenie.net)                 #"
echo "#              Email for queries: info@rackgenie.net                 #"
echo "#                                                                    #"
echo "######################################################################"

# Pause for 3 seconds to allow the user to read the header
sleep 3

# Display an instruction message for the user
echo ""
echo ""
echo "######## Please Select the Option if you want to Optimize your cPanel Server with Apache & PHP-FPM or nGinx & suPHP PHP Handler ########"
echo ""

# Display additional details about each option
echo "########################################################################"
echo "##### THIS IS IMPORTANT, PLEASE READ CAREFULLY BEFORE SELECTING    #####"
echo "#####                                                              #####"
echo "##### First Option will Install Apache Web Server with PHP-FPM     #####"
echo "#####                                                              #####"
echo "##### Second Option will Install nGinx Web Server with suPHP       #####"
echo "########################################################################"

# Pause for 2 seconds to allow the user to read the options
sleep 2

# Start a loop until a valid choice is made
while true; do
  # Display the options for the user to choose from
  echo ""
  echo "Please select an option:"
  echo "1. Optimize and Secure cPanel Server with Apache & PHP-FPM (Recommended)"
  echo "2. Optimize and Secure cPanel Server with NGinx Web Server & suPHP PHP Handler"

  # Read the user's choice
  read -p "Enter your choice (1 or 2): " choice

  # Depending on the user's choice, perform the relevant action
  case $choice in
    1)
      # User chose to optimize and secure cPanel server with Apache & PHP-FPM
      echo "Optimize and Secure cPanel Server with Apache & PHP-FPM (Recommended)"
      # Make the optimization script executable and run it
      chmod +x optimize-apache.sh && sh optimize-apache.sh ;
      break
      ;;
    2)
      # User chose to optimize and secure cPanel server with NGinx & suPHP PHP Handler
      echo "Optimize and Secure cPanel Server with NGinx Web Server & suPHP PHP Handler"
      # Make the optimization script executable and run it
      chmod +x optimize-nginx.sh && sh optimize-nginx.sh ;
      break
      ;;
    *)
      # User made an invalid choice. Prompt them to choose again
      echo "Invalid choice. Please choose 1 or 2."
      ;;
  esac
done
