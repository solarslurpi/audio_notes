#!/bin/bash

# Create transcripts directory
mkdir -p transcripts

# List of video IDs to skip
SKIP_IDS=("MNlooDlfJns","hsI2lbN8fj8","lVY1RlrX9fc","gW96L6Qycms")

# Get playlist videos and process each one
yt-dlp --flat-playlist --get-id  --cookies-from-browser firefox "https://www.youtube.com/playlist?list=PLAwQgDrCXDe8kwi6revZdWubuTTWM9INn" | while read -r video_id; do
    # Check if video_id is in skip list
    skip=false
    for skip_id in "${SKIP_IDS[@]}"; do
        if [ "$video_id" = "$skip_id" ]; then
            echo "Skipping video $video_id"
            skip=true
            break
        fi
    done

    if [ "$skip" = true ]; then
        continue
    fi

    yt2o.sh -c -d transcripts "https://www.youtube.com/watch?v=$video_id"
done