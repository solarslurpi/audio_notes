#!/bin/bash

# Create transcripts directory
mkdir -p transcripts

# Counter for episodes
count=0

# Get playlist videos and process each one
yt-dlp --flat-playlist --get-id  --cookies-from-browser firefox "https://www.youtube.com/playlist?list=PLAwQgDrCXDe8kwi6revZdWubuTTWM9INn" | while read -r video_id; do
    count=$((count + 1))

    # Skip first 3 episodes
    if [ $count -le 4 ]; then
        echo "Skipping episode $count"
        continue
    fi

   yt2o.sh -c -d transcripts "https://www.youtube.com/watch?v=$video_id"
done