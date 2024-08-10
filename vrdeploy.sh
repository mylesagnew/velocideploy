#!/bin/bash

# Colors for output
red='\e[31m'
yellow='\e[33m'
blue='\e[34m'
clear='\e[0m'

# Function to install Velociraptor
function velociraptor_install() {
    if ! sudo ./velociraptor config generate -i; then
        echo -e "${red}Failed to generate Velociraptor config.${clear}"
        return 1
    fi

    if ! sudo sed -e '60,/bind_address:/{s/0.0.0.0/0.0.0.0/}' -i server.config.yaml; then
        echo -e "${red}Failed to modify server config.${clear}"
        return 1
    fi

    if ! sudo sed -e 's/localhost/aws_public_ip/g' -i client.config.yaml; then
        echo -e "${red}Failed to modify client config.${clear}"
        return 1
    fi

    if ! sudo ./velociraptor --config server.config.yaml debian server; then
        echo -e "${red}Failed to install Velociraptor server.${clear}"
        return 1
    fi

    if ! sudo apt install ./velociraptor_server*.deb; then
        echo -e "${red}Failed to install Velociraptor server deb package.${clear}"
        return 1
    fi

    if ! sudo ./velociraptor --config client.config.yaml debian client; then
        echo -e "${red}Failed to install Velociraptor client.${clear}"
        return 1
    fi

    sudo mv velociraptor_client*.deb ./Linux/nix-velociraptor.deb
    sudo mv client.config.yaml ./Windows

    echo -e "${yellow}Velociraptor installation completed.${clear}"
}

# Function to upload files to Dropbox
function db_upload() {
    echo "Enter your Dropbox token:"
    read -s ACCESS_TOKEN

    if [[ -z "$ACCESS_TOKEN" ]]; then
        echo -e "${red}Dropbox token is required.${clear}"
        return 1
    fi

    files_to_upload=(
        "./Windows/client.config.yaml"
        "./Windows/win-velociraptor.msi"
        "./Linux/nix-velociraptor.deb"
        "./Windows/win_install.bat"
        "./Linux/nix_install.sh"
    )

    dropbox_paths=(
        "/Windows/Velociraptor.config.yaml"
        "/Windows/win-velociraptor.msi"
        "/Linux/nix-velociraptor.deb"
        "/Windows/win_install.bat"
        "/Linux/nix_install.sh"
    )

    for i in "${!files_to_upload[@]}"; do
        if [ -f "${files_to_upload[$i]}" ]; then
            sudo curl -X POST https://content.dropboxapi.com/2/files/upload \
                --header "Authorization: Bearer $ACCESS_TOKEN" \
                --header "Dropbox-API-Arg: {\"path\": \"${dropbox_paths[$i]}\"}" \
                --header "Content-Type: application/octet-stream" \
                --data-binary @"${files_to_upload[$i]}"
            echo -e "${yellow}Uploaded ${files_to_upload[$i]} to Dropbox.${clear}"
        else
            echo -e "${red}File not found: ${files_to_upload[$i]}. Skipping...${clear}"
        fi
    done
}

# Function to upload files to AWS S3
function aws_upload() {
    echo "Enter your AWS S3 bucket name:"
    read BUCKET_NAME

    if [[ -z "$BUCKET_NAME" ]]; then
        echo -e "${red}S3 bucket name is required.${clear}"
        return 1
    fi

    files_to_upload=(
        "./Windows/client.config.yaml"
        "./Windows/win-velociraptor.msi"
        "./Linux/nix-velociraptor.deb"
        "./Windows/win_install.bat"
        "./Linux/nix_install.sh"
    )

    s3_paths=(
        "Windows/Velociraptor.config.yaml"
        "Windows/win-velociraptor.msi"
        "Linux/nix-velociraptor.deb"
        "Windows/win_install.bat"
        "Linux/nix_install.sh"
    )

    for i in "${!files_to_upload[@]}"; do
        if [ -f "${files_to_upload[$i]}" ]; then
            aws s3 cp "${files_to_upload[$i]}" "s3://$BUCKET_NAME/${s3_paths[$i]}"
            if [ $? -eq 0 ]; then
                echo -e "${yellow}Uploaded ${files_to_upload[$i]} to S3 bucket $BUCKET_NAME.${clear}"
            else
                echo -e "${red}Failed to upload ${files_to_upload[$i]} to S3 bucket $BUCKET_NAME.${clear}"
            fi
        else
            echo -e "${red}File not found: ${files_to_upload[$i]}. Skipping...${clear}"
        fi
    done
}

# Function to add a user to Velociraptor
function adduser() {
    echo "Enter user's name:"
    read VR_USERNAME

    if [[ -z "$VR_USERNAME" ]]; then
        echo -e "${red}Username is required.${clear}"
        return 1
    fi

    if ! sudo -u velociraptor --sh velociraptor user add "$VR_USERNAME" --role=administrator; then
        echo -e "${red}Failed to add user.${clear}"
        return 1
    fi

    echo -e "${yellow}User $VR_USERNAME added successfully.${clear}"
}

# Function to reinstall Velociraptor
function reinstall() {
    if ! sudo apt remove -y velociraptor-server; then
        echo -e "${red}Failed to remove Velociraptor server.${clear}"
        return 1
    fi
    velociraptor_install
}

# Main menu
function menu() {
    while true; do
        echo -ne "
    ${yellow}____   ____     .__         .__    .___            .__                
\   \ /   /____ |  |   ____ |__| __| _/____ ______ |  |   ____ ___.__.
 \   Y   // __ \|  | _/ ___\|  |/ __ |/ __ \\____ \|  |  /  _ <   |  |
  \     /\  ___/|  |_\  \___|  / /_/ \  ___/|  |_> >  |_(  <_> )___  |
   \___/  \___  >____/\___  >__\____ |\___  >   __/|____/\____// ____|
              \/          \/        \/    \/|__|               \/ ${clear}
    ${blue}(1)${clear} Install Velociraptor Server
    ${blue}(2)${clear} Upload Sensors to Dropbox
    ${blue}(3)${clear} Upload Sensors to AWS S3
    ${blue}(4)${clear} Add User
    ${blue}(5)${clear} Reinstall Velociraptor
    ${blue}(0)${clear} Exit
    Choose an option: "
        read -r choice
        case $choice in
        1) velociraptor_install ;;
        2) db_upload ;;
        3) aws_upload ;;
        4) adduser ;;
        5) reinstall ;;
        0) exit 0 ;;
        *) echo -e "${red}Incorrect option. Try again.${clear}" ;;
        esac
    done
}

# Start the menu
menu
