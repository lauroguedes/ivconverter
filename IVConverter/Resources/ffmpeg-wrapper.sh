#!/bin/bash

# Attempt to find ffmpeg executable
possible_paths=(
  "/opt/homebrew/bin/ffmpeg"
  "/opt/homebrew/Cellar/ffmpeg/7.1.1_1/bin/ffmpeg"
  "/usr/local/bin/ffmpeg"
  "/usr/bin/ffmpeg"
)

FFMPEG_PATH=""

# Check if any of the paths exist
for path in "${possible_paths[@]}"; do
  if [ -x "$path" ]; then
    FFMPEG_PATH="$path"
    break
  fi
done

# If not found in common locations, try using 'which'
if [ -z "$FFMPEG_PATH" ]; then
  WHICH_FFMPEG=$(which ffmpeg 2>/dev/null)
  if [ -x "$WHICH_FFMPEG" ]; then
    FFMPEG_PATH="$WHICH_FFMPEG"
  fi
fi

# Exit if no ffmpeg found
if [ -z "$FFMPEG_PATH" ]; then
  echo "Error: Could not find ffmpeg executable." >&2
  exit 1
fi

# Execute ffmpeg with all arguments passed to this script
"$FFMPEG_PATH" "$@"