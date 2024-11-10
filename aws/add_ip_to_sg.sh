#!/bin/bash

# Define paths to the Terraform files
TF_STATE_FILE="terraform.tfstate"  # Path to the Terraform state file
TF_MAIN_FILE="main.tf"             # Path to the main Terraform configuration file

# Function to parse AWS region from main.tf
get_region_from_main_tf() {
  if [ ! -f "$TF_MAIN_FILE" ]; then
    echo "Terraform main.tf file not found at $TF_MAIN_FILE"
    exit 1
  fi
  
  # Extract AWS region from main.tf using grep
  AWS_REGION=$(grep -oP 'region\s*=\s*"\K[^"]+' "$TF_MAIN_FILE")
  
  # Check if the region was extracted correctly
  if [ -z "$AWS_REGION" ]; then
    echo "Error: Could not retrieve AWS region from main.tf file."
    exit 1
  fi
  
  echo "AWS Region: $AWS_REGION"
}

# Function to parse security group rule ID from the Terraform state file
get_security_group_rule_id_from_state() {
  if [ ! -f "$TF_STATE_FILE" ]; then
    echo "Terraform state file not found at $TF_STATE_FILE"
    exit 1
  fi
  
  # Extract Security Group Rule ID from the Terraform state file
  SECURITY_GROUP_RULE_ID=$(jq -r '.resources[] | select(.type=="aws_security_group_rule" and .name=="group-velo-gui") | .instances[0].attributes.security_group_id // empty' "$TF_STATE_FILE")

  # Check if the Security Group Rule ID was extracted correctly
  if [ -z "$SECURITY_GROUP_RULE_ID" ]; then
    echo "Error: Could not retrieve security group rule ID from Terraform state file."
    exit 1
  fi
  
  echo "Security Group Rule ID: $SECURITY_GROUP_RULE_ID"
}

# Function to get IP address either from input or automatically
get_ip() {
  if [ -n "$1" ]; then
    IP="$1"
  else
    read -p "Enter the IP address to allow (leave blank to use your current public IP): " IP
    if [ -z "$IP" ]; then
      IP=$(curl -s http://checkip.amazonaws.com)
      if [ -z "$IP" ]; then
        echo "Failed to retrieve public IP address."
        exit 1
      fi
    fi
  fi
  echo "IP to allow: $IP"
}

# Function to check if IP exists in security group rules
ip_exists() {
  aws ec2 describe-security-groups --region "$AWS_REGION" \
    --group-ids "$SECURITY_GROUP_RULE_ID" \
    --query "SecurityGroups[*].IpPermissions[*].IpRanges[*].CidrIp" \
    --output text | grep -q "${IP}/32"
}

# Gather AWS region from main.tf
get_region_from_main_tf

# Gather the security group rule ID from the Terraform state file
get_security_group_rule_id_from_state

# Get the IP address from the user or automatically
get_ip "$1"

# Add IP if it doesn't exist
if ip_exists; then
  echo "IP $IP already exists in the security group rules."
else
  echo "Adding IP $IP to the security group rules."
  aws ec2 authorize-security-group-ingress \
    --region "$AWS_REGION" \
    --group-id "$SECURITY_GROUP_RULE_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "${IP}/32"
  if [ $? -eq 0 ]; then
    echo "Successfully added IP $IP to the security group."
  else
    echo "Failed to add IP to the security group."
  fi
fi
