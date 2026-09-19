#!/bin/bash

INTERNAL="eDP-1"
EXTERNAL="HDMI-A-1"

if [ "$1" = "close" ]; then
    if hyprctl monitors -j | jq -e --arg m "$EXTERNAL" '.[] | select(.name==$m)' >/dev/null 2>&1; then
        hyprctl eval "hl.monitor({ output = \"$INTERNAL\", disabled = true })"
    else
        systemctl suspend
    fi
else
    hyprctl eval "hl.monitor({ output = \"$INTERNAL\", mode = \"1920x1080@60\", position = \"-1920x0\", scale = 1, disabled = false })"
fi
