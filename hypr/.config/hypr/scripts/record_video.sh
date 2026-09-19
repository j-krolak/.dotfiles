#!/usr/bin/env bash
# Record a screen region to /tmp/recording.mp4, then copy the file as a URI
# so it can be pasted straight into apps that accept dropped files.
set -euo pipefail

source "$(dirname "$0")/lib_select_region.sh"

# Click a window to record it whole, or drag for a free-form region
region=$(select_region) || exit 0

wf-recorder -y -g "$region" -f /tmp/recording.mp4
echo "file:///tmp/recording.mp4" | wl-copy -t text/uri-list
notify-send -t 3000 "Recording" ".mp4 copied to clipboard"
