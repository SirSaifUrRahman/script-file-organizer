#!/bin/bash
# organize.sh - organize files in a directory by extension

if [ $# -ne 1 ]; then
    echo "Usage: $0 /home/habib/Downloads"
    exit 1
fi

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Error: $dir is not a directory."
    exit 1
fi

cd "$dir" || exit 1

# You can define categories here
declare -A types
types=( ["Images"]="jpg jpeg png gif" ["Docs"]="pdf docx txt" ["Archives"]="zip tar gz" )

for file in *; do
    # skip directories
    [ -f "$file" ] || continue
    ext="${file##*.}"
    moved=0
    for cat in "${!types[@]}"; do
        for e in ${types[$cat]}; do
            if [[ "$ext" == "$e" ]]; then
                mkdir -p "$cat"
                mv "$file" "$cat/"
                moved=1
                break
            fi
        done
        [ $moved -eq 1 ] && break
    done
    # if not matched, you could move to “Others”
    if [ $moved -eq 0 ]; then
        mkdir -p "Others"
        mv "$file" "Others/"
    fi
done

echo "Organization complete."

