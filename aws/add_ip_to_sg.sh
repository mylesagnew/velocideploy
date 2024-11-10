#!/bin/bash

# Define the path to the Terraform state file
TF_STATE_FILE="terraform.tfstate"  # Update the path if necessary

# Function to parse Terraform state for AWS region and security group rule ID for "group-velo-gui"
get_aws_details_from_state() {
  if [ ! -f "$TF_STATE_FILE" ]; then
    echo "Terraform state file not found at $TF_STATE_FILE"
    exit 1
  fi
  
  # Extract AWS region and security group ID for "group-velo-gui" from the Terraform state file
  AWS_REGION=$(jq -r '.resources[] | select(.type=="aws_security_group" and .name=="group-velo-gui") | .instances[0].attributes.vpc_id' "$TF_STATE_FILE")
  SECURITY_GROUP_ID=$(jq -r '.resources[] | select(.type=="aws_security_group" and .name=="group-velo-gui") | .instances[0].attributes.id' "$TF_STATE_FILE")
  
  # Check if the values were extracted correctly
  if [ -z "$AWS_REGION" ]; then
    echo "Error: Could not retrieve AWS region from Terraform state file."
    exit 1
  fi
  if [ -z "$SECURITY_GROUP_ID" ]; then
    echo "Error: Could not retrieve security group ID from Terraform state file."
    exit 1
  fi
  
  echo "AWS Region: $AWS_REGION"
  echo "Security Group ID: $SECURITY_GROUP_ID"
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
    --group-ids "$SECURITY_GROUP_ID" \
    --query "SecurityGroups[*].IpPermissions[*].IpRanges[*].CidrIp" \
    --output text | grep -q "${IP}/32"
}

# Gather AWS region and security group ID from Terraform state file
get_aws_details_from_state

# Get the IP address from the user or automatically
get_ip "$1"

# Add IP if it doesn't exist
if ip_exists; then
  echo "IP $IP already exists in the security group rules."
else
  echo "Adding IP $IP to the security group rules."
  aws ec2 authorize-security-group-ingress \
    --region "$AWS_REGION" \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "${IP}/32"
  if [ $? -eq 0 ]; then
    echo "Successfully added IP $IP to the security group."
  else
    echo "Failed to add IP to the security group."
  fi
fi
