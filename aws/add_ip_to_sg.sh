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

# Function to parse security group rule details based on rule name
get_security_group_rule_details_from_state() {
  local rule_name=$1
  if [ ! -f "$TF_STATE_FILE" ]; then
    echo "Terraform state file not found at $TF_STATE_FILE"
    exit 1
  fi
  
  # Extract Security Group Rule details from the Terraform state file
  SECURITY_GROUP_RULE_ID=$(jq -r ".resources[] | select(.type==\"aws_security_group_rule\" and .name==\"$rule_name\") | .instances[0].attributes.security_group_id // empty" "$TF_STATE_FILE")
  PORT=$(jq -r ".resources[] | select(.type==\"aws_security_group_rule\" and .name==\"$rule_name\") | .instances[0].attributes.from_port // empty" "$TF_STATE_FILE")
  PROTOCOL=$(jq -r ".resources[] | select(.type==\"aws_security_group_rule\" and .name==\"$rule_name\") | .instances[0].attributes.protocol // empty" "$TF_STATE_FILE")

  # Check if the Security Group Rule ID, Port, and Protocol were extracted correctly
  if [ -z "$SECURITY_GROUP_RULE_ID" ] || [ -z "$PORT" ] || [ -z "$PROTOCOL" ]; then
    echo "Error: Could not retrieve security group rule details from Terraform state file."
    exit 1
  fi
  
  echo "Security Group Rule ID: $SECURITY_GROUP_RULE_ID"
  echo "Port: $PORT"
  echo "Protocol: $PROTOCOL"
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

# Function to check if IP exists in the specified security group rule for the specific port and protocol
ip_exists() {
  aws ec2 describe-security-groups --region "$AWS_REGION" \
    --group-ids "$SECURITY_GROUP_RULE_ID" \
    --query "SecurityGroups[*].IpPermissions[?FromPort==\`${PORT}\` && ToPort==\`${PORT}\` && IpProtocol==\`${PROTOCOL}\`].IpRanges[*].CidrIp" \
    --output text | grep -q "${IP}/32"
}

# Function to add IP to the specified security group rule
add_ip_to_sg() {
  if ip_exists; then
    echo "IP $IP already exists in the security group rules."
  else
    echo "Adding IP $IP to the security group rules."
    aws ec2 authorize-security-group-ingress \
      --region "$AWS_REGION" \
      --group-id "$SECURITY_GROUP_RULE_ID" \
      --protocol "$PROTOCOL" \
      --port "$PORT" \
      --cidr "${IP}/32"
    if [ $? -eq 0 ]; then
      echo "Successfully added IP $IP to the security group."
    else
      echo "Failed to add IP to the security group."
    fi
  fi
}

# Gather AWS region from main.tf
get_region_from_main_tf

# Display menu options
echo "Select an option:"
echo "1. Add IP to SSH (group-velo-ssh)"
echo "2. Add IP to ADMIN GUI (group-velo-gui)"
read -p "Enter choice [1-2]: " choice

# Execute the selected option
case $choice in
  1)
    get_security_group_rule_details_from_state "group-velo-ssh"
    get_ip "$1"
    add_ip_to_sg
    ;;
  2)
    get_security_group_rule_details_from_state "group-velo-gui"
    get_ip "$1"
    add_ip_to_sg
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac
