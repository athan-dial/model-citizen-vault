#!/bin/bash
# YouTube Transcript Ingestion Script
# Usage: ./ingest-youtube.sh <youtube-url>
#
# Downloads transcript from YouTube video and creates a vault-compliant
# Markdown file in sources/youtube/

set -e

VAULT_DIR="$HOME/model-citizen-vault"
OUTPUT_DIR="$VAULT_DIR/sources/youtube"
TEMP_DIR="/tmp/yt-ingest-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <youtube-url>"
    echo "Example: $0 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'"
    exit 1
}

# Check arguments
if [ -z "$1" ]; then
    usage
fi

URL="$1"

# Extract video ID from various YouTube URL formats
extract_video_id() {
    local url="$1"
    local video_id=""

    # youtube.com/watch?v=ID
    if [[ "$url" =~ youtube\.com/watch\?v=([^&]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    # youtu.be/ID
    elif [[ "$url" =~ youtu\.be/([^?]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    # youtube.com/embed/ID
    elif [[ "$url" =~ youtube\.com/embed/([^?]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    # youtube.com/shorts/ID
    elif [[ "$url" =~ youtube\.com/shorts/([^?]+) ]]; then
        video_id="${BASH_REMATCH[1]}"
    fi

    echo "$video_id"
}

VIDEO_ID=$(extract_video_id "$URL")

if [ -z "$VIDEO_ID" ]; then
    echo -e "${RED}Error: Could not extract video ID from URL${NC}"
    echo "URL: $URL"
    exit 1
fi

echo -e "${YELLOW}Video ID: $VIDEO_ID${NC}"

# Check for existing file (idempotency)
mkdir -p "$OUTPUT_DIR"
EXISTING=$(find "$OUTPUT_DIR" -name "${VIDEO_ID}-*.md" 2>/dev/null | head -1)

if [ -n "$EXISTING" ]; then
    echo -e "${YELLOW}File already exists: $EXISTING${NC}"
    echo "Skipping download (idempotent)"
    exit 0
fi

# Create temp directory
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

echo "Fetching video metadata..."

# Get metadata (use TAB as delimiter for reliable parsing)
METADATA=$(yt-dlp --skip-download --print "%(id)s	%(title)s	%(upload_date)s" "$URL" 2>/dev/null)

if [ -z "$METADATA" ]; then
    echo -e "${RED}Error: Could not fetch video metadata${NC}"
    exit 1
fi

# Parse tab-separated values
ID=$(echo "$METADATA" | cut -f1)
TITLE=$(echo "$METADATA" | cut -f2)
UPLOAD_DATE=$(echo "$METADATA" | cut -f3)

echo -e "Title: ${GREEN}$TITLE${NC}"
echo "Upload date: $UPLOAD_DATE"

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-60)

# Format date as YYYY-MM-DD
FORMATTED_DATE="${UPLOAD_DATE:0:4}-${UPLOAD_DATE:4:2}-${UPLOAD_DATE:6:2}"

echo "Downloading transcript..."

# Download transcript (try auto-subs first, then manual)
yt-dlp --write-auto-subs --skip-download --sub-lang en --sub-format vtt \
    --output "$TEMP_DIR/%(id)s.%(ext)s" "$URL" 2>/dev/null || true

# Find the VTT file
VTT_FILE=$(find "$TEMP_DIR" -name "*.vtt" | head -1)

if [ -z "$VTT_FILE" ]; then
    echo -e "${YELLOW}Warning: No transcript found. Creating note with metadata only.${NC}"
    TRANSCRIPT="[No transcript available for this video]"
else
    echo "Parsing VTT transcript..."

    # Parse VTT to plain text (remove timestamps, cue markers, etc.)
    TRANSCRIPT=$(cat "$VTT_FILE" | \
        grep -v "^WEBVTT" | \
        grep -v "^Kind:" | \
        grep -v "^Language:" | \
        grep -v "^$" | \
        grep -v "^[0-9][0-9]:[0-9][0-9]" | \
        grep -v -- "-->" | \
        grep -v "^[0-9]*$" | \
        sed 's/<[^>]*>//g' | \
        tr '\n' ' ' | \
        sed 's/  */ /g' | \
        sed 's/^ //' | \
        sed 's/ $//')
fi

# Create output filename
FILENAME="${VIDEO_ID}-${SLUG}.md"
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

echo "Writing to: $OUTPUT_FILE"

# Write markdown file with frontmatter
cat > "$OUTPUT_FILE" << EOF
---
title: "$TITLE"
date: $FORMATTED_DATE
status: "inbox"
tags: []
source: "YouTube"
source_url: "$URL"
video_id: "$VIDEO_ID"
---

$TRANSCRIPT
EOF

echo -e "${GREEN}Success!${NC} Created: $FILENAME"
echo "Location: $OUTPUT_FILE"
