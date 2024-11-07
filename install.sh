#!/bin/bash

# Define variables
REPO_URL="https://github.com/mylesagnew/velocideploy/archive/refs/heads/main.zip"
ZIP_FILE="velocideploy-main.zip"
EXTRACT_DIR="velocideploy-main"

# Download the repository
echo "Downloading repository..."
wget -O $ZIP_FILE $REPO_URL

# Check if the download was successful
if [[ $? -ne 0 ]]; then
  echo "Failed to download the repository. Exiting."
  exit 1
fi

# Extract the ZIP file
echo "Extracting files..."
unzip -q $ZIP_FILE

# Check if the extraction was successful
if [[ $? -ne 0 ]]; then
  echo "Failed to extract files. Exiting."
  exit 1
fi

# Set permissions for all .sh files
echo "Setting executable permissions on .sh files..."
find $EXTRACT_DIR -type f -name "*.sh" -exec chmod 755 {} \;

# Clean up the ZIP file
rm $ZIP_FILE

echo "Installation complete. Files are ready in the '$EXTRACT_DIR' directory."
