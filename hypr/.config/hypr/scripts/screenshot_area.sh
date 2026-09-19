#!/bin/bash

source "$(dirname "$0")/lib_clipse_history.sh"
source "$(dirname "$0")/lib_select_region.sh"

# Click a window to grab it whole, or drag for a free-form region
if [ "${1:-}" = "--freeze" ]; then
	region=$(select_region_frozen) || exit 0
else
	region=$(select_region) || exit 0
fi

file=$(hypr_region_label "$region")

# Snapshot existing clipse image entries so we can spot the new one it creates below
old_paths=$(clipse_snapshot_image_paths)

grim -g "$region" - | wl-copy

# Rename the clipse history entry clipse just created for this screenshot to use
# the window title instead of its default `<filesize>-<timestamp>.png` name.
(clipse_tag_new_image "$old_paths" "$file") &
disown
