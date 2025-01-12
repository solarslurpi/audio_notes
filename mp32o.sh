#!/bin/bash

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--obsidian-dir)
            OBSIDIAN_DIR="$2"
            shift 2
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Usage: mp32o.sh [-d obsidian_dir] [-c] mp3_file"
            exit 1
            ;;
        *)
            # This is the MP3 file argument
            MP3_PATH=$1
            shift
            break
            ;;
    esac
done

# Check if mp3 file is provided and exists
if [ -z "$MP3_PATH" ]; then
    echo "Usage: mp32o.sh [-d obsidian_dir] [-c] mp3_file"
    exit 1
fi

if [[ ! "$MP3_PATH" =~ ^/ ]]; then
    # If path doesn't start with /, it's relative - prepend current directory
    MP3_PATH="$(pwd)/$MP3_PATH"
fi
if [ ! -f "$MP3_PATH" ]; then
    echo "❌ Error: MP3 file not found: $MP3_PATH"
    exit 1
fi

# Validate and set OUTPUT_DIR
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="output"  # Default if not set
fi
# Ensure clean path without special characters
OUTPUT_DIR=$(echo "$OUTPUT_DIR" | tr -d '[]' | tr -d '\r')

# Same for OBSIDIAN_DIR.
if [ -z "$OBSIDIAN_DIR" ]; then
    OBSIDIAN_DIR="transcripts"  # Default if not set
fi
OBSIDIAN_DIR=$(echo "$OBSIDIAN_DIR" | tr -d '[]' | tr -d '\r')

# Default values
CLEANUP=false

# Add timing variables
START_TIME=$(date +%s)
LAST_STEP_TIME=$START_TIME
LAST_STEP_NAME=""

# Function to print elapsed time of the previous step
print_step() {
    local current_time=$(date +%s)
    # Print the time taken for the previous step if there was one
    if [ ! -z "$LAST_STEP_NAME" ]; then
        local step_duration=$((current_time - LAST_STEP_TIME))
        echo "⏱️ Previous step '$LAST_STEP_NAME' took: ${step_duration}s"
    fi
    # Set up for the new step
    echo "$1"
    LAST_STEP_TIME=$current_time
    LAST_STEP_NAME="$1"
}

cleanup() {
    echo "🧹 Cleaning up temporary files..."
    rm -rf "${OUTPUT_DIR:?}"/* # :? prevents deletion if OUTPUT_DIR is empty
    rmdir "$OUTPUT_DIR"
}




basename="${MP3_PATH##*/}"  # Remove path
BASENAME="${basename%.*}"   # Remove extension

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Remove any carriage returns Windows inserts 
OUTPUT_DIR=$(echo "$OUTPUT_DIR" | tr -d '\r')
BASENAME=$(echo "$BASENAME" | tr -d '\r')
OBSIDIAN_DIR=$(echo "$OBSIDIAN_DIR" | tr -d '\r')
# Check if Obsidian directory exists, create if it doesn't
if [ ! -d "$OBSIDIAN_DIR" ]; then
    echo "📁 Creating Obsidian directory: $OBSIDIAN_DIR"
    mkdir -p "$OBSIDIAN_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ Error: Could not create directory: $OBSIDIAN_DIR"
        exit 1
    fi
fi

if [ "$DEBUG" = true ]; then
    echo "🔍 DEBUG VALUES:"
    echo "Command: $0 $@"
    echo "Working Directory: $(pwd)"
    echo "Input MP3: $MP3_PATH"
    echo "BASENAME: $BASENAME"
    echo "OBSIDIAN_DIR: $OBSIDIAN_DIR"
    echo "OUTPUT_DIR: $OUTPUT_DIR"
    echo "CLEANUP: $CLEANUP"
    echo "URL: $1"
    exit 0
fi
 
print_step "🎙️ Transcribing audio..."
JSON_PATH="${OUTPUT_DIR}/${BASENAME}.json"


#     --flash True \
insanely-fast-whisper \
    --flash True \
    --batch-size 4 \
    --timestamp "chunk" \
    --model-name "openai/whisper-large-v3" \
    --file-name "$MP3_PATH" \
    --transcript-path "$JSON_PATH"

print_step "📝 Creating Obsidian note..."
# the --mp3-source option is handled by click and passed in as the mp3_source
create-obsidian-note "${OUTPUT_DIR}" "${BASENAME}" "$OBSIDIAN_DIR" --mp3-source "$MP3_PATH"

# For the final step
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
echo "⏱️ Previous step '$LAST_STEP_NAME' took: $((END_TIME - LAST_STEP_TIME))s"
echo -e "\n⏱️ Total processing time: ${TOTAL_TIME}s"
echo "✅ Processing complete!"

# Clean up if requested
if [ "$CLEANUP" = true ]; then
    cleanup
fi