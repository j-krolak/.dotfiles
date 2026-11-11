#!/bin/bash
# Whole-screen screenshot to clipboard. Default: focused monitor; --all: every monitor.

source "$(dirname "$0")/lib_clipse_history.sh"

old_paths=$(clipse_snapshot_image_paths)

if [ "${1:-}" = "--all" ]; then
	grim - | wl-copy
	file="all screens"
else
	output=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
	grim -o "$output" - | wl-copy
	file="$output"
fi

(clipse_tag_new_image "$old_paths" "$file") &
disown
