#!/bin/bash

# Load environment variables
source .env

# Default values
CLEANUP=false

# Add timing variables
START_TIME=$(date +%s)
LAST_STEP_TIME=$START_TIME
LAST_STEP_NAME=""

# Function to print elapsed time of the previous step
print_step() {
    local current_time=$(date +%s)
    if [ ! -z "$LAST_STEP_NAME" ]; then
        local step_duration=$((current_time - LAST_STEP_TIME))
        echo "⏱️ Previous step '$LAST_STEP_NAME' took: ${step_duration}s"
    fi
    echo "$1"
    LAST_STEP_TIME=$current_time
    LAST_STEP_NAME="$1"
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            OUTPUT_DIR="$2"
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
    echo "Usage: yt2o.sh [-d output_dir] [-c] <youtube_url>"
    exit 1
fi

URL=$1
echo "URL: $URL"
# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "OUTPUT_DIR: $OUTPUT_DIR"
print_step "📝 Setting the filename..."
BASENAME=$(yt-dlp --cookies-from-browser firefox --restrict-filenames --get-title "$URL" | \
    tr -cd '[:alnum:]_-' | \
    cut -c1-50)

# Remove any carriage returns
OUTPUT_DIR=$(echo "$OUTPUT_DIR" | tr -d '\r')
BASENAME=$(echo "$BASENAME" | tr -d '\r')
echo "BASENAME: $BASENAME"

if [ "$DEBUG" = true ]; then
    echo "DEBUG VALUES:"
    echo "BASENAME: $BASENAME"
    echo "OUTPUT_DIR: $OUTPUT_DIR"
    echo "CLEANUP: $CLEANUP"
    echo "URL: $1"
    exit 0
fi

print_step "📥 Getting metadata and mp3 from the video..."
yt-dlp --verbose \
    --cookies-from-browser firefox \
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
    # --flash True \
insanely-fast-whisper \
 --batch-size 4 \
    --timestamp "chunk" \
    --model-name "openai/whisper-large-v3" \
    --file-name "$MP3_PATH" \
    --transcript-path "$JSON_PATH"

print_step "📝 Creating Obsidian note..."
create-obsidian-note "${OUTPUT_DIR}" "${BASENAME}" "$OUTPUT_DIR"

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