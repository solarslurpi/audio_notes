#!/bin/bash

# Create transcripts directory
mkdir -p transcripts

# List of video IDs to skip as bash array.
SKIP_IDS=("MNlooDlfJns" "hsI2lbN8fj8" "gW96L6Qycms" "lVY1RlrX9fc")

# Convert skip IDs array to string with | as separator for pattern matching. e.g.: "MNlooDlfJns|hsI2lbN8fj8|lVY1RlrX9fc|gW96L6Qycms"
SKIP_PATTERN=$(IFS="|"; echo "${SKIP_IDS[*]}")

# Get playlist videos and process each one
yt-dlp --flat-playlist --get-id  --cookies-from-browser firefox "https://www.youtube.com/playlist?list=PLAwQgDrCXDe8kwi6revZdWubuTTWM9INn" | while read -r video_id; do

    # =~ is regex matching in bash.
    # ^($SKIP_PATTERN)$ is a regex pattern that matches any of the SKIP_PATTERN strings, starting (^) and ending ($) with the first and last character of SKIP_PATTERN.
    echo "---Checking if $video_id matches $SKIP_PATTERN"
    if [[ $video_id =~ ^($SKIP_PATTERN)$ ]]; then
        echo "Skipping video $video_id"
        continue
    fi

    yt2o.sh -c -d transcripts "https://www.youtube.com/watch?v=$video_id"
done