#!/bin/bash

# Load environment variables
source .env

# Validate and set OUTPUT_DIR
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="output"  # Default if not set
fi
# Ensure clean path without special characters
OUTPUT_DIR=$(echo "$OUTPUT_DIR" | tr -d '[]' | tr -d '\r')

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
        *)
            break
            ;;
    esac
done

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: ./yt2o.sh [-d obsidian_dir] [-c] <youtube_url>"
    exit 1
fi

URL=$1

# Create output directory
mkdir -p "$OUTPUT_DIR"
# See the README for reasoning behind cookie-from-browser.
print_step "📝 Setting the filename..."
# Removed --cookies-from-browser firefox \ This was used because some of the Cannabis videos were age-restricted. It doesn't seem to consistently work.
BASENAME=$(/usr/local/bin/yt-dlp  --restrict-filenames --print filename -o "%(title)s" "$URL" | tr -d '#')
echo "BASENAME: $BASENAME"
# Remove any carriage returns Windows insertsfrom the variables
OUTPUT_DIR=$(echo "$OUTPUT_DIR" | tr -d '\r')
BASENAME=$(echo "$BASENAME" | tr -d '\r')
OBSIDIAN_DIR=$(echo "$OBSIDIAN_DIR" | tr -d '\r')
# Check if Obsidian directory exists
if [ ! -d "$OBSIDIAN_DIR" ]; then
    echo "❌ Error: Obsidian directory does not exist: $OBSIDIAN_DIR"
    echo "Please check your .env file and ensure the OBSIDIAN_DIR path is correct."
    echo "Current OBSIDIAN_DIR: $OBSIDIAN_DIR"
    exit 1
fi

if [ "$DEBUG" = true ]; then
    echo "DEBUG VALUES:"
    echo "BASENAME: $BASENAME"
    echo "OBSIDIAN_DIR: $OBSIDIAN_DIR"
    echo "OUTPUT_DIR: $OUTPUT_DIR"
    echo "CLEANUP: $CLEANUP"
    echo "URL: $1"
    exit 0
fi
  # Removed --cookies-from-browser firefox \ This was used because some of the Cannabis videos were age-restricted. It doesn't seem to consistently work.
print_step "📥 Getting metadata and mp3 from the video..."
/usr/local/bin/yt-dlp --verbose \
    --restrict-filenames \
    --format "bestaudio/best" \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 96 \
    --postprocessor-args "-ac 1 -ar 44100" \
    --write-info-json \
    --output "${BASENAME}" \
    --paths "${OUTPUT_DIR}" \
    "$URL"

if [ $? -ne 0 ]; then
    echo "Error: Could not download video. Please check your URL."
    exit 1
fi

print_step "🎙️ Transcribing audio..."
MP3_PATH="${OUTPUT_DIR}/${BASENAME}.mp3"
JSON_PATH="${OUTPUT_DIR}/${BASENAME}.json"

echo "Checking if MP3 exists: $MP3_PATH"
if [ ! -f "$MP3_PATH" ]; then
    echo "❌ MP3 file not found at: $MP3_PATH"
    ls -la "${OUTPUT_DIR}"
    exit 1
fi
#     --flash True \
insanely-fast-whisper \
    --flash True \
    --batch-size 4 \
    --timestamp "chunk" \
    --model-name "openai/whisper-large-v3" \
    --file-name "$MP3_PATH" \
    --transcript-path "$JSON_PATH"

print_step "📝 Creating Obsidian note..."
create-obsidian-note "${OUTPUT_DIR}" "${BASENAME}" "$OBSIDIAN_DIR"

# For the final step
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
echo "⏱️ Previous step '$LAST_STEP_NAME' took: $((END_TIME - LAST_STEP_TIME))s"
echo -e "\n⏱️ Total processing time: ${TOTAL_TIME}s"
echo "✅ Processing complete!"

# Clean up if requested
if [ "$CLEANUP" = true ]; then
    echo "🧹 Cleaning up temporary files..."
    rm -rf "$OUTPUT_DIR"/*
    rmdir "$OUTPUT_DIR"
fi