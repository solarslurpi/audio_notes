#!/bin/bash

# Default settings
delete_original=false
cleanup=false
OUTPUT_DIR="output"
OBSIDIAN_DIR="G:/My Drive/Audios_To_Knowledge/knowledge/AskGrowBuddy/AskGrowBuddy/new_notes"

# Error handling
set -e  # Exit on any error
trap 'echo "❌ Error on line $LINENO. Exit code: $?"' ERR

# Add timing variables
START_TIME=$(date +%s)
LAST_STEP_TIME=$START_TIME
LAST_STEP_NAME=""

# Function to print elapsed time of the previous step
print_step() {
    local current_time=$(date +%s)
    if [ ! -z "$LAST_STEP_NAME" ]; then
        local step_duration=$((current_time - LAST_STEP_TIME))
        printf "⏱️  Previous step '%s' took: %ds\n" "$LAST_STEP_NAME" "$step_duration"
    fi
    printf "\n🔄 %s\n" "$1"
    LAST_STEP_TIME=$current_time
    LAST_STEP_NAME="$1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $(basename "$0") [-d] [-c] <input.mp3>

Options:
    -d    Delete original MP3 file after processing
    -c    Clean up temporary files after processing

Example:
    $(basename "$0") -d -c input.mp3
EOF
    exit 1
}

# Parse command line options
while getopts "dc" opt; do
    case $opt in
        d) delete_original=true ;;
        c) cleanup=true ;;
        *) show_usage ;;
    esac
done

# Shift past the options to get the input file
shift $((OPTIND-1))

# Validate input
[[ $# -ne 1 ]] && show_usage

input_file="$1"

# Validate file
if [[ ! -f "$input_file" ]]; then
    echo "❌ Error: Input file '$input_file' not found"
    exit 1
fi

# Validate extension
if [[ "${input_file,,}" != *.mp3 ]]; then
    echo "❌ Error: Input file must be an MP3 file"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get basename without extension
BASENAME=$(basename "$input_file" .mp3)

# Main processing
print_step "Copying MP3 to output directory"
cp "$input_file" "${OUTPUT_DIR}/${BASENAME}.mp3" || {
    echo "❌ Failed to copy MP3 file"
    exit 1
}

print_step "Transcribing audio"
insanely-fast-whisper --batch-size 4 \
    --timestamp "chunk" \
    --model-name "openai/whisper-large-v3" \
    --file-name "${OUTPUT_DIR}/${BASENAME}.mp3" \
    --transcript-path "${OUTPUT_DIR}/${BASENAME}.json" || {
    echo "❌ Transcription failed"
    exit 1
}

print_step "Creating Obsidian note"
create-obsidian-note "${OUTPUT_DIR}" "${BASENAME}" "$OBSIDIAN_DIR" || {
    echo "❌ Failed to create Obsidian note"
    exit 1
}

# Cleanup and final steps
if [[ "$cleanup" == true ]]; then
    print_step "Cleaning up temporary files"
    rm -rf "${OUTPUT_DIR}"/* && rmdir "$OUTPUT_DIR"
fi

if [[ "$delete_original" == true ]]; then
    print_step "Deleting original file"
    rm "$input_file"
fi

# Final timing report
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
printf "\n⏱️  Previous step '%s' took: %ds\n" "$LAST_STEP_NAME" $((END_TIME - LAST_STEP_TIME))
printf "\n⏱️  Total processing time: %ds\n" "$TOTAL_TIME"
echo "✅ Processing complete!"
