#!/bin/bash

# Load the VOLUME_BASE_PATH from the .env file
if [ -f .env ]; then
  source .env
else
  echo ".env file not found. Please create it and specify VOLUME_BASE_PATH."
  exit 1
fi

# Check if VOLUME_BASE_PATH is set
if [ -z "$VOLUME_BASE_PATH" ]; then
  echo "VOLUME_BASE_PATH is not set in the .env file. Please specify it."
  exit 1
fi

# Define a list of services
services=("portainer" "homer") # Add the names of all services here

# Loop through each service
for service in "${services[@]}"; do
  compose_file="./$service/docker-compose.yml"
  
  # Check if the docker-compose.yml file exists for the service
  if [ -f "$compose_file" ]; then
    echo "Starting Docker Compose for $service with VOLUME_BASE_PATH=$VOLUME_BASE_PATH"
    # Export VOLUME_BASE_PATH so it's available to docker-compose
    VOLUME_BASE_PATH="$VOLUME_BASE_PATH" docker-compose -f "$compose_file" up -d
  else
    echo "docker-compose.yml for $service not found. Skipping."
  fi
done

echo "All specified Docker Compose services have been started."
