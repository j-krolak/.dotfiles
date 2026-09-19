#!/usr/bin/env bash
# Record a screen region to a GIF: capture as mp4, then run a two-pass
# ffmpeg palette conversion (better quality/size than a direct GIF encode),
# and copy the result as a URI.
set -euo pipefail

source "$(dirname "$0")/lib_select_region.sh"

# Click a window to record it whole, or drag for a free-form region
region=$(select_region) || exit 0

wf-recorder -y -c libx264rgb -g "$region" -f /tmp/recording.mp4

palette_filter='[0:v] fps=15,scale=1080:-1:flags=lanczos,split [a][b];[a] palettegen [p];[b][p] paletteuse=dither=none'
ffmpeg -i /tmp/recording.mp4 -filter_complex "$palette_filter" /tmp/recording.gif -y

echo "file:///tmp/recording.gif" | wl-copy -t text/uri-list
notify-send -t 3000 "Recording" "GIF copied to clipboard"
