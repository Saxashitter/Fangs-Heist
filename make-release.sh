pk3name=FangsHeist

rm -rf .tmp

read -p "Optimize songs?: " musicopti
read -p "Optimize sounds?: " sound
read -p "Is this a release build?: " rel

# Use a ternary-like operator to set variables concisely
# If the input is 'y' or 'Y', the variable is 0, otherwise it's 1.
optimize=$([[ "$musicopti" =~ ^[yY]$ ]] && echo 0 || echo 1)
optimizesounds=$([[ "$sound" =~ ^[yY]$ ]] && echo 0 || echo 1)

# Set 'release' and 'prefix' based on the 'rel' input
release=$([[ "$rel" =~ ^[yY]$ ]] && echo 0 || echo 1)
prefix=$([[ "$rel" =~ ^[yY]$ ]] && echo "-release" || echo "-test")

rm -rf "$pk3name$prefix.pk3"

# Optimize songs.
#!/bin/bash

# A function to optimize audio files in a specified directory
function optimize_audio() {
    # Check if a directory path was provided
    if [ -z "$1" ]; then
        echo "Error: No directory specified."
        return 1
    fi

	# Check if a directory path was provided
    if [ -z "$1" ]; then
        echo "Error: No directory specified."
        return 1
    fi

    mkdir -p "$2"

	touch md5save.txt

    local AUDIO_DIR="$1"
    local TARGET_LUFS="-14"

    echo "Processing audio files in '$AUDIO_DIR'..."

    # Use find to locate audio files and pass their absolute paths to xargs
    find "$AUDIO_DIR" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.aac" -o -iname "*.ogg" \) -print0 | \
    xargs -0 -I {} -P 8 bash -c '
        file="{}"
        source_dir='"$1"'
        output_dir='"$2"'
        move_dir='"$3"'
        peak='"$4"'

        # Calculate MD5 hash for the current file
        md5=$(md5sum "$file" | awk "{print \$1}")

        # Check for an existing entry with the same filename
        matching_line=$(grep "^${file}::${md5}" "md5save.txt")

        if [ -n "$matching_line" ]; then
            known_md5=$(echo "$matching_line" | cut -d":" -f3)

            if [ "$md5" != "$known_md5" ]; then
                echo "File has the same name but a different MD5. Removing old entry..."
                temp_file=$(mktemp)
                grep -vF -- "${matching_line}" "md5save.txt" > "$temp_file"
                mv "$temp_file" "md5save.txt"
                echo "Old entry removed."
            else
                echo "Skipping $(basename "$file") - Already processed."
                exit 0
            fi
        fi

        echo "Converting and normalizing $(basename "$file")"
            
        # Extract the subdirectory path relative to the source directory.
        relative_path="${file#$source_dir/}"
        
        # Get the directory part of the relative path.
        output_subdir=$(dirname "$relative_path")
        
        # Create the necessary subdirectory in the output directory.
        mkdir -p "$output_dir/$output_subdir"
        
        # Construct the final output path.
        filename_no_ext=$(basename -- "${file%.*}")
        output_path="$output_dir/$output_subdir/$filename_no_ext.ogg"
        
        # ... (rest of the code)
        ffmpeg -nostdin -threads 1 -loglevel quiet -y -i "$file" -filter:a "loudnorm=I=-14:tp=$peak" -ar 32000 "$output_path"
        mv "$file" "$move_dir"
        mv "$output_path" "${file%.*}.ogg"
        new_path="${file%.*}.ogg"

        # Calculate MD5 hash for the current file
        md5=$(md5sum "$new_path" | awk "{print \$1}")

        if [ $? -eq 0 ]; then
            echo "Successfully converted."
        else
            echo "Error converting."
        fi

        echo "${new_path}::${md5}" >> md5save.txt
    '
    echo "Processing complete for '$AUDIO_DIR'."
}

if [[ "$optimize" == 0 ]]; then
	optimize_audio "src/Music" ".tmp/Music" "assets/unoptimized/music" "0"
fi
if [[ "$optimizesounds" == 0 ]]; then
	optimize_audio "src/Sounds" ".tmp/Sounds" "assets/unoptimized/sounds" "-6"
fi

cd src
zip -r9 -q "../$pk3name$prefix.pk3" *
cd ..
if [ -f ".tmp" ]; then
	rm -r .tmp
fi
echo "Done!"