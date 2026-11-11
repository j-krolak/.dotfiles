#!/usr/bin/env bash
# Record a screen region to /tmp/recording.mp4, then copy the file as a URI
# so it can be pasted straight into apps that accept dropped files.
set -euo pipefail

source "$(dirname "$0")/lib_select_region.sh"

# --screen: whole focused monitor. Otherwise click a window to record it
# whole, or drag for a free-form region.
if [ "${1:-}" = "--screen" ]; then
	output=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
	wf-recorder -y -o "$output" -f /tmp/recording.mp4
else
	region=$(select_region) || exit 0
	wf-recorder -y -g "$region" -f /tmp/recording.mp4
fi
echo "file:///tmp/recording.mp4" | wl-copy -t text/uri-list
notify-send -t 3000 "Recording" ".mp4 copied to clipboard"
