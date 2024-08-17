#!/bin/bash

# Colors for output
red='\e[31m'
yellow='\e[33m'
blue='\e[34m'
clear='\e[0m'

# Function to install Velociraptor on AWS
function install_aws() {
    echo -e "${blue}Installing Velociraptor on AWS...${clear}"
    if ! bash aws/aws-velocideploy.sh; then
        echo -e "${red}Failed to install Velociraptor on AWS.${clear}"
        return 1
    fi
}

# Function to install Velociraptor on Azure
function install_azure() {
    echo -e "${blue}Installing Velociraptor on Azure...${clear}"
    if ! bash azure/azure-velocideploy.sh; then
        echo -e "${red}Failed to install Velociraptor on Azure.${clear}"
        return 1
    fi
}

# Function to install Velociraptor on GCP
function install_gcp() {
    echo -e "${blue}Installing Velociraptor on GCP...${clear}"
    if ! bash gcp/gcp-velocideploy.sh; then
        echo -e "${red}Failed to install Velociraptor on GCP.${clear}"
        return 1
    fi
}

# Main menu
function menu() {
    while true; do
        echo -ne "
    ${yellow}
____   ____     .__         .__    .___            .__                
\   \ /   /____ |  |   ____ |__| __| _/____ ______ |  |   ____ ___.__.
 \   Y   // __ \|  | _/ ___\|  |/ __ |/ __ \\____ \|  |  /  _ <   |  |
  \     /\  ___/|  |_\  \___|  / /_/ \  ___/|  |_> >  |_(  <_> )___  |
   \___/  \___  >____/\___  >__\____ |\___  >   __/|____/\____// ____|
              \/          \/        \/    \/|__|               \/ ${clear}
    ${blue}(1)${clear} Install Velociraptor on AWS
    ${blue}(2)${clear} Install Velociraptor on Azure
    ${blue}(3)${clear} Install Velociraptor on GCP
    ${blue}(0)${clear} Exit
    Choose an option: "
        read -r choice
        case $choice in
        1) install_aws ;;
        2) install_azure ;;
        3) install_gcp ;;
        0) exit 0 ;;
        *) echo -e "${red}Incorrect option. Try again.${clear}" ;;
        esac
    done
}

# Start the menu
menu
