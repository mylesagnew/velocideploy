#!/bin/bash

# Colors for output
red='\e[31m'
yellow='\e[33m'
blue='\e[34m'
clear='\e[0m'

function velociraptor_install() {
    # Generate the configuration files
    sudo ./velociraptor config generate -i
    
    # Modify server configuration to listen on all IPs
    sudo sed -i '60,/bind_address:/s/127.0.0.1/0.0.0.0/' server.config.yaml
    
    # Replace 'localhost' with the AWS public IP in the client configuration
    sudo sed -i 's/localhost/aws_public_ip/' client.config.yaml

    # Install the server package
    sudo ./velociraptor --config server.config.yaml debian server
    sudo apt install -y ./velociraptor*server.deb

    # Install the client package and move files to appropriate directories
    sudo ./velociraptor --config client.config.yaml debian client
    sudo mkdir -p ./Linux
    sudo mv velociraptor*client.deb ./Linux/nix-velociraptor.deb
    sudo mkdir -p ./Windows
    sudo mv client.config.yaml ./Windows/
}


# Function to upload files to Dropbox
function db_upload() {
    echo "Enter your Dropbox token:"
    read ACCESS_TOKEN

    sudo curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/Windows/Velociraptor.config.yaml\"}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @./Windows/client.config.yaml

    sudo curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/Windows/win-velociraptor.msi\"}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @./Windows/win-velociraptor.msi

    sudo curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/Linux/nix-velociraptor.deb\"}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @./Linux/nix-velociraptor.deb

    sudo curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/Windows/win_install.bat\"}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @./Windows/win_install.bat

    sudo curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/Linux/nix_install.sh\"}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary @./Linux/nix_install.sh
}

# Function to add a user to Velociraptor
function adduser() {
    echo "Enter user's name:"
    read VR_USERNAME

    sudo -u velociraptor --sh velociraptor user add $VR_USERNAME --role=administrator
    exit
}

# Function to reinstall Velociraptor
function reinstall() {
    sudo apt remove velociraptor-server
    velociraptor_install
}

# Menu function with the original aws-deploy.sh header retained
function menu() {
    echo -ne "
    ${yellow}
____   ____     .__         .__    .___            .__                
\   \ /   /____ |  |   ____ |__| __| _/____ ______ |  |   ____ ___.__.
 \   Y   // __ \|  | _/ ___\|  |/ __ |/ __ \\____ \|  |  /  _ <   |  |
  \     /\  ___/|  |_\  \___|  / /_/ \  ___/|  |_> >  |_(  <_> )___  |
   \___/  \___  >____/\___  >__\____ |\___  >   __/|____/\____// ____|
              \/          \/        \/    \/|__|               \/ ${clear}
    ${blue}(1)${clear} Install Velociraptor Server
    ${blue}(2)${clear} Upload Sensors
    ${blue}(3)${clear} Add User
    ${blue}(4)${clear} Reinstall Velociraptor
    ${blue}(0)${clear} Exit
    Choose an option: "
    read -r choice
    case $choice in
    1) velociraptor_install ; menu ;;
    2) db_upload ; menu ;;
    3) adduser ; menu ;;
    4) reinstall ; menu ;;
    0) exit 0 ;;
    *) echo -e "${red}Incorrect option. Try again.${clear}" ; menu ;;
    esac
}

# Start the menu
menu
