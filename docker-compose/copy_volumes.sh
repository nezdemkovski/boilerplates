#!/bin/bash

# Load the VOLUME_BASE_PATH from the .env file
source .env

# Check if the variable is set
if [ -z "$VOLUME_BASE_PATH" ]; then
  echo "VOLUME_BASE_PATH is not set in the .env file. Please specify it."
  exit 1
fi

# Create the VOLUME_BASE_PATH directory if it does not exist
mkdir -p "$VOLUME_BASE_PATH"

# Define a list of services and copy their volumes
services=("portainer" "homer") # Add the names of all services here

for service in "${services[@]}"; do
  service_volume_path="./$service/volumes"
  target_volume_path="$VOLUME_BASE_PATH/$service"

  # Copy the volume files if they exist
  if [ -d "$service_volume_path" ]; then
    echo "Copying $service_volume_path to $target_volume_path"
    mkdir -p "$target_volume_path"
    cp -r "$service_volume_path/"* "$target_volume_path/"
  else
    echo "Volume directory for $service not found. Skipping."
  fi
done

echo "Volume copying completed."
