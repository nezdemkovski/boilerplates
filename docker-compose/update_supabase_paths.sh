#!/bin/bash

# Define the path to the Supabase folder
SUPABASE_PATH="./supabase"

# Check if the Supabase folder exists
if [ ! -d "$SUPABASE_PATH" ]; then
  echo "Supabase folder not found at $SUPABASE_PATH. Please check the path."
  exit 1
fi

# Files to be updated
FILES=("docker-compose.s3.yml" "docker-compose.yml")

# Loop through each file and replace volume paths
for file in "${FILES[@]}"; do
  file_path="$SUPABASE_PATH/$file"

  # Check if the file exists
  if [ -f "$file_path" ]; then
    echo "Updating paths in $file_path..."
    
    # Replace occurrences of "./volumes/" with "${VOLUME_BASE_PATH}/supabase/"
    # Use an empty string after -i for macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's|\./volumes/|${VOLUME_BASE_PATH}/supabase/|g' "$file_path"
    else
      sed -i 's|\./volumes/|${VOLUME_BASE_PATH}/supabase/|g' "$file_path"
    fi

    echo "Paths updated in $file_path."
  else
    echo "File $file_path not found. Skipping."
  fi
done

echo "All specified files have been processed."
