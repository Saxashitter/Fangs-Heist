#!/bin/bash

# Define the directory to scan and the output file
DIRECTORY="./src/Music"
OUTPUT_FILE="md5_list.txt"

# Clear the output file if it exists, or create it if it doesn't
> "$OUTPUT_FILE"

# Use find to locate all files and process each one
find "$DIRECTORY" -type f -print0 | while IFS= read -r -d '' file; do
    # Calculate the MD5 hash of the file
    md5=$(md5sum "$file" | awk '{print $1}')
    # Append the path and MD5 to the output file
    echo "${file}::${md5}" >> "$OUTPUT_FILE"
done

echo "MD5 list saved to $OUTPUT_FILE"
