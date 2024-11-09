#!/bin/bash

# Colors for output
red='\e[31m'
yellow='\e[33m'
blue='\e[34m'
clear='\e[0m'

function velociraptor_install() {
    # Variables
    SERVER_CONFIG="server.config.yaml"
    CLIENT_CONFIG="client.config.yaml"
    LINUX_DIR="./Linux"
    WINDOWS_DIR="./Windows"
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)  # Retrieves AWS public IP

    # Generate the configuration files
    sudo ./velociraptor config generate -i
    
    # Modify server configuration to listen on all IPs
    sudo sed -i '60,/bind_address:/s/0.0.0.0/0.0.0.0/' "$SERVER_CONFIG"
    
    # Replace 'localhost' with the AWS public IP in the client configuration
    sudo sed -i "s/localhost/$PUBLIC_IP/" "$CLIENT_CONFIG"

    # Install the server package
    sudo ./velociraptor --config "$SERVER_CONFIG" debian server
    chmod +x velociraptor_server*.deb
    sudo dpkg -i  ./velociraptor_server*.deb

    # Install the client package and move files to appropriate directories
    sudo ./velociraptor --config "$CLIENT_CONFIG" debian client
    mkdir -p "$LINUX_DIR" "$WINDOWS_DIR"
    sudo mv velociraptor*client.deb "$LINUX_DIR/nix-velociraptor.deb"
    sudo mv "$CLIENT_CONFIG" "$WINDOWS_DIR/"

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
    sudo dpkg -r velociraptor_server*.deb
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
