#!/bin/bash

# Load the VOLUME_BASE_PATH from the .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found. Please create it and specify VOLUME_BASE_PATH."
  exit 1
fi

# Check if the variable is set
if [ -z "$VOLUME_BASE_PATH" ]; then
  echo "VOLUME_BASE_PATH is not set in the .env file. Please specify it."
  exit 1
fi

# Create the VOLUME_BASE_PATH directory if it does not exist
mkdir -p "$VOLUME_BASE_PATH"

# Define a list of services and copy their volumes
services=("portainer" "homer" "factorio-server-manager")

for service in "${services[@]}"; do
  service_volume_path="./$service/volumes"
  target_volume_path="$VOLUME_BASE_PATH/$service"

  # Check if the target directory already exists
  if [ -d "$target_volume_path" ]; then
    echo "Directory for $service already exists at $target_volume_path. Skipping creation and copy."
  else
    # Create the directory and copy files if it doesn't exist
    echo "Creating directory for $service at $target_volume_path"
    mkdir -p "$target_volume_path"

    if [ -d "$service_volume_path" ]; then
      echo "Copying $service_volume_path to $target_volume_path"
      cp -r "$service_volume_path/"* "$target_volume_path/"
    else
      echo "Volume directory for $service not found. Skipping file copy."
    fi
  fi
done

echo "Volume copying completed."
