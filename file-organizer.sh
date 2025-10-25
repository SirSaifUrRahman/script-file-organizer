#!/bin/bash

# organize.sh - safely and efficiently organize files in a directory by extension
# Features:
#   • Safe execution using strict Bash settings
#   • Organized logging (all output redirected to a timestamped log file)
#   • Collision handling (avoids overwriting existing files)
#   • Categorization by file type (easily extendable)
#   • No terminal output — only writes to log file


# === Safe Execution Mode (Enable safe globbing) ===
set -euo pipefail             # Exit on error, unset variable use, or pipeline (connected by pipe |) failure
shopt -s nullglob             # skip unmatched globs  # empty match expands to nothing (avoids literal *)
# shopt -s dotglob            # Uncomment to include hidden files (optional)


# === Usage & Directory Validation ===
if [ $# -ne 1 ]; then
    echo "Usage: Pass an argument where you'd like the files to be organized like /home/habib/Downloads/ and run your script like that bash $0 /home/habib/Downloads/ "
    exit 1
fi

dir="$1"

# Check if provided argument is a valid directory
if [ ! -d "$dir" ]; then
    echo "Error: $dir is not a valid directory."
    exit 1
fi

# Move into the target directory (exit if it fails)
cd "$dir" || exit 1

# === Logging setup ===
timestamp=$(date +"%Y-%m-%d_%H-%M-%S") #2025-10-21_10-04-24
log_file="$dir/organize_${timestamp}.log"

# Redirect all stdout and stderr to log file
# exec >"$log_file" 2>&1
exec > >(tee "$log_file") 2>&1 # tee -a 

# Write log header
echo "=== File Organization Log ==="
echo "Timestamp: $(date)"
echo "Directory: $dir"
echo "========================================"

# === Define File Type Categories ===
# Each category maps to one or more file extensions.
# To add new types, simply extend this associative array.
declare -A types=(
    ["Images"]="jpg jpeg png gif bmp svg webp"
    ["Docs"]="pdf docx doc txt odt xlsx csv"
    ["Archives"]="zip tar gz bz2 rar 7z tar.gz"
    ["Videos"]="mp4 mkv avi mov"
    ["Audio"]="mp3 wav flac m4a"
)

# === Gather All Regular Files ===
# This ensures we only operate on actual files (not directories).
files=( * )
regular_files=()

for f in "${files[@]}"; do
    [[ -f "$f" ]] && regular_files+=("$f")
done

printf "Regular files detected: %d\n\n" "${#regular_files[@]}"

# === File Processing Loop ===
# Iterate through each file, detect its type, and move it to the proper folder.
for file in "${regular_files[@]}"; do

    # Skip the log file itself to prevent self-movement
    [[ "$file" == organize_*.log ]] && continue

    filename="$file"
    ext=""
    moved=false

    # --- Determine File Extension ---
    # Extract file extension and normalize to lowercase.
    if [[ "$filename" == *.* ]]; then
        ext="${filename##*.}"
        ext="${ext,,}"
    fi

    # Special handling for multi-part extensions like `.tar.gz`
    [[ "${filename,,}" == *.tar.gz ]] && ext="tar.gz"

    # --- Match File Extension to Category ---
    # Loop through each category in the associative array.
    for cat in "${!types[@]}"; do
    # Iterate through all extensions under this category
        for e in ${types[$cat]}; do
        # Compare extension; if matched, move file
            if [[ "$ext" == "$e" ]]; then
                mkdir -p -- "$cat"
                # --- Handle Filename Collisions ---
                # If same name exists, rename with timestamp
                dest="$cat/$filename"
                [[ -e "$dest" ]] && {
                    base="${filename%.*}"
                    ext_part="${filename##*.}"
                    ts=$(date +%s)
                    dest="$cat/${base}_${ts}.${ext_part}"
                    echo "Collision detected, renamed to: $dest"
                }
                mv -- "$file" "$dest"
                echo "Moved: '$file' → '$dest'"
                moved=true
                break 2
            fi
        done
    done

    # --- Handle Unrecognized Files ---
    # If no match found in defined categories, move to "Others"

    if ! $moved; then
        mkdir -p -- "Others"

        # Handle name collisions in Others as well
        dest="Others/$filename"
        [[ -e "$dest" ]] && {
            base="${filename%.*}"
            ext_part="${filename##*.}"
            ts=$(date +%s)
            dest="Others/${base}_${ts}.${ext_part}"
            echo "Collision detected, renamed to: $dest"
        }
        mv -- "$file" "$dest"
        echo "Moved unrecognized file: '$file' → '$dest'"
    fi
done

echo "Organization complete for directory: $dir"
echo "Log file saved at: $log_file"

