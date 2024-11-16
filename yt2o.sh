#!/bin/bash

# Default values
CLEANUP=false
OBSIDIAN_DIR="G:/My Drive/Audios_To_Knowledge/knowledge/AskGrowBuddy/AskGrowBuddy/new_notes"
OUTPUT_DIR="output"

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
while getopts "d:c" opt; do
    case $opt in
        d) OBSIDIAN_DIR="$OPTARG";;
        c) CLEANUP=true;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    esac
done

shift $((OPTIND-1))

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: ./yt2o.sh [-d obsidian_dir] [-c] <youtube_url>"
    exit 1
fi

URL=$1

# Create output directory
mkdir -p "$OUTPUT_DIR"

print_step "📝 Setting the filename..."
BASENAME=$(/usr/local/bin/yt-dlp --restrict-filenames --print filename -o "%(title)s" "$URL" | tr -d '#')

echo "BASENAME: $BASENAME"

print_step "📥 Getting metadata and mp3 from the video..."
/usr/local/bin/yt-dlp --verbose \
    --restrict-filenames \
    --format "bestaudio/best" \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 96 \
    --postprocessor-args "-ac 1 -ar 44100" \
    --write-info-json \
    --output "$BASENAME" \
    --paths "$OUTPUT_DIR" \
    "$URL"

if [ $? -ne 0 ]; then
    echo "Error: Could not download video. Please check your URL."
    exit 1
fi

print_step "🎙️ Transcribing audio..."
# Using large-v2 model because transcribing larger files caused the system to crash with the large-v3 openai model.
# Although the verdict is out. Because there are "optimizations" to try:
# - --batch-size 4 (default is 124). The larger batch size uses more memory.
# -- timestamp "chunk" (default is "chunk"). Chunk is faster but less accurate.
# insanely-fast-whisper --model-name "distil-whisper/large-v2" --file-name "${OUTPUT_DIR}/${BASENAME}.mp3" --transcript-path "${OUTPUT_DIR}/${BASENAME}.json"

insanely-fast-whisper --flash True --batch-size 4 --timestamp "chunk" --model-name "openai/whisper-large-v3" --file-name "${OUTPUT_DIR}/${BASENAME}.mp3" --transcript-path "${OUTPUT_DIR}/${BASENAME}.json"

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