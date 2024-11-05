#!/bin/bash

# Define a list of services to ignore
ignored_services=()

# Loop through each folder in the current directory
for dir in */; do
  # Remove the trailing slash from the folder name
  service="${dir%/}"
  
  # Check if the service is in the ignored list
  if [[ " ${ignored_services[@]} " =~ " ${service} " ]]; then
    echo "$service is in the ignored list. Skipping."
    continue
  fi

  # Define the path to the docker-compose.yml file
  compose_file="./$service/docker-compose.yml"
  
  # Check if the docker-compose.yml file exists for the service
  if [ -f "$compose_file" ]; then
    echo "Starting Docker Compose for $service"
    docker-compose -f "$compose_file" up -d
  else
    echo "docker-compose.yml for $service not found. Skipping."
  fi
done

echo "All specified Docker Compose services have been started."