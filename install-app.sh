#!/bin/bash

# Load the JSON configuration
CONFIG_FILE="app_config.json"
SECRETS_FILE="secrets.json"
SCRIPTS_DIR="scripts"

# Function to read JSON data
get_json_value() {
    local key=$1
    jq -r "$key" "$CONFIG_FILE"
}

# Function to read a value from secrets.json if it exists
get_secret_value() {
    local key=$1
    if [ -f "$SECRETS_FILE" ]; then
        jq -r "$key" "$SECRETS_FILE"
    else
        echo ""
    fi
}

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Install jq to use this script."
    exit 1
fi

# Load global configuration values
VOLUME_BASE_PATH=$(get_json_value ".config.volume_base_path")
DOCKER_COMPOSE_PATH=$(get_json_value ".config.docker_compose_path")
export VOLUME_BASE_PATH

echo "Using VOLUME_BASE_PATH: $VOLUME_BASE_PATH"
echo "Docker Compose files will be output to: $DOCKER_COMPOSE_PATH"

# Copy the scripts to the root of docker_compose_path if not already present
if [ ! -f "$DOCKER_COMPOSE_PATH/start_services.sh" ] || [ ! -f "$DOCKER_COMPOSE_PATH/stop_services.sh" ]; then
    echo "Copying start/stop scripts to $DOCKER_COMPOSE_PATH for the first time."
    mkdir -p "$DOCKER_COMPOSE_PATH"
    cp "$SCRIPTS_DIR/start_services.sh" "$DOCKER_COMPOSE_PATH/"
    cp "$SCRIPTS_DIR/stop_services.sh" "$DOCKER_COMPOSE_PATH/"
fi

# Function to prompt for app-specific variables and export them
prompt_variables() {
    local app=$1
    echo "Configuring $app..."

    # Load and iterate over required variables from app_config.json
    for var in $(jq -r ".apps[\"$app\"].variables | keys[]" "$CONFIG_FILE"); do
        local description=$(jq -r ".apps[\"$app\"].variables.$var" "$CONFIG_FILE")
        local secret_value=$(get_secret_value ".apps[\"$app\"].variables.$var")

        # If secret_value exists, use it as the default
        if [ "$secret_value" != "null" ] && [ -n "$secret_value" ]; then
            echo -n "$description [$secret_value]: "
            read -r value
            value=${value:-$secret_value}  # Use entered value or default to secret
        else
            echo -n "$description: "
            read -r value
        fi

        export $var="$value"
    done
}

# Function to copy and configure the app
configure_app() {
    local app=$1
    local folder=$(get_json_value ".apps[\"$app\"].folder")
    local output_dir="${DOCKER_COMPOSE_PATH}/${app}"
    local volume_dir="${VOLUME_BASE_PATH}/${app}"

    # Ensure the app folder exists
    if [ ! -d "$folder" ]; then
        echo "App folder for $app not found at $folder"
        exit 1
    fi

    # Prompt for each variable needed
    prompt_variables "$app"

    # Process Docker Compose file
    local compose_file="$folder/docker-compose.yml"
    local output_file="$output_dir/docker-compose.yml"

    # Create the output directory if it doesn't exist
    mkdir -p "$output_dir"

    # Substitute variables in the Docker Compose template and save to output
    cp "$compose_file" "$output_file"
    sed -i "s|\${VOLUME_BASE_PATH}|$VOLUME_BASE_PATH|g" "$output_file"
    for var in $(jq -r ".apps[\"$app\"].variables | keys[]" "$CONFIG_FILE"); do
        value="${!var}"
        sed -i "s|\${$var}|$value|g" "$output_file"
    done
    echo "Configuration for $app saved to $output_file"

    # Check if a volumes directory exists in the app folder
    local volumes_source="$folder/volumes"
    if [ -d "$volumes_source" ]; then
        echo "Copying volume files for $app to $volume_dir"

        # Copy the volume files with directory structure and substitute variables in each file
        find "$volumes_source" -type f | while read -r file; do
            # Determine the relative path to recreate the directory structure
            local relative_path="${file#$volumes_source/}"
            local destination_file="$volume_dir/$relative_path"

            # Create the target directory if it doesn't exist
            mkdir -p "$(dirname "$destination_file")"

            # Copy the file and replace only the defined variables
            cp "$file" "$destination_file"
            sed -i "s|\${VOLUME_BASE_PATH}|$VOLUME_BASE_PATH|g" "$destination_file"
            for var in $(jq -r ".apps[\"$app\"].variables | keys[]" "$CONFIG_FILE"); do
                value="${!var}"
                sed -i "s|\${$var}|$value|g" "$destination_file"
            done
            echo "Copied and configured $file to $destination_file"
        done
    fi
}

# Main script entry
if [ -z "$1" ]; then
    echo "Usage: ./install-app.sh <app_name>"
    exit 1
fi

app_name=$1

# Check if the app exists in config
if jq -e ".apps[\"$app_name\"]" "$CONFIG_FILE" > /dev/null; then
    configure_app "$app_name"
else
    echo "App $app_name not found in config."
    exit 1
fi