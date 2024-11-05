#!/bin/bash

cd "${0%/*}"
# Ensure Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found. Installing..."
    curl -O https://releases.hashicorp.com/terraform/1.5.3/terraform_1.5.3_linux_amd64.zip
    unzip terraform_1.5.3_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
fi

# Ensure Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "Ansible not found. Installing..."
    sudo yum install python3 -y
    pip3 install --user ansible
    export PATH=$PATH:~/.local/bin
fi

# Initialize Terraform and apply configurations
terraform init
terraform apply 

# Run Ansible playbook
env NO_PROXY='*' ansible-playbook -i inventory velociraptor.yml