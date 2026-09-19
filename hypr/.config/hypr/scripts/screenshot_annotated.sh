#!/bin/bash

source "$(dirname "$0")/lib_clipse_history.sh"
source "$(dirname "$0")/lib_select_region.sh"

# Click a window to grab it whole, or drag for a free-form region
region=$(select_region) || exit 0

file=$(hypr_region_label "$region")

tmpfile="/tmp/shot_$(date +%s).png"
textfile="/tmp/text_$(date +%s).png"
boxfile="/tmp/box_$(date +%s).png"

grim -g "$region" "$tmpfile" || exit 1

font="JetBrainsMono-NF-Bold"
pointsize=16
padding_x=10
padding_y=6
margin=8   # distance from screenshot edge
radius=12  # corner roundness

# 1. Render just the text, tightly cropped
convert -font "$font" -pointsize "$pointsize" -fill white -background none label:"$file" "$textfile"

# 2. Measure the rendered text
read -r text_w text_h <<< "$(identify -format "%w %h" "$textfile")"

box_w=$((text_w + padding_x * 2))
box_h=$((text_h + padding_y * 2))

# 3. Draw a rounded-rect background at that exact size
convert -size "${box_w}x${box_h}" xc:none \
  -fill '#000000AA' \
  -draw "roundrectangle 0,0,$((box_w - 1)),$((box_h - 1)),${radius},${radius}" \
  "$boxfile"

# 4. Center the text on top of the box (guarantees perfect centering)
convert "$boxfile" "$textfile" -gravity center -composite "$boxfile"

# 5. Composite the finished bubble onto the screenshot, top-right corner
convert "$tmpfile" "$boxfile" -gravity NorthEast -geometry "+${margin}+${margin}" -composite "$tmpfile"

# Snapshot existing clipse image entries so we can spot the new one it creates below
old_paths=$(clipse_snapshot_image_paths)

wl-copy < "$tmpfile"

notify-send -t 3000 "Screenshot" "Copied with label: $file" 2>/dev/null

rm -f "$tmpfile" "$textfile" "$boxfile"

# Rename the clipse history entry clipse just created for this screenshot to use
# the window title instead of its default `<filesize>-<timestamp>.png` name.
(clipse_tag_new_image "$old_paths" "$file") &
disown
