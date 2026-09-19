#!/usr/bin/env bash
# Region picker that also accepts a plain click on a window.
#
# slurp highlights any boxes fed on stdin and selects the one under the cursor
# on a simple click, while a drag still produces a free-form region. Without
# `-r` both gestures stay available.
# https://github.com/emersion/slurp

hypr_window_boxes() {
	local visible
	visible=$(hyprctl -j monitors | jq -c '[.[] | .activeWorkspace.id, .specialWorkspace.id] | unique')

	hyprctl -j clients | jq -r --argjson visible "$visible" '
		.[]
		| select(.mapped and (.hidden | not))
		| select(.workspace.id as $id | $visible | index($id))
		| select(.size[0] > 0 and .size[1] > 0)
		| "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"
	'
}

# Usage: region=$(select_region [extra slurp args...]) || exit 0
select_region() {
	hypr_window_boxes | slurp "$@"
}

# Same, but over a still image of the screen so animations/menus stay put while
# picking. hyprpicker -r -z renders the frozen copy and holds it until killed.
select_region_frozen() {
	local picker_pid region
	hyprpicker -r -z >/dev/null 2>&1 &
	picker_pid=$!
	sleep 0.2

	region=$(hypr_window_boxes | slurp "$@")
	local status=$?

	kill "$picker_pid" 2>/dev/null
	printf '%s\n' "$region"
	return $status
}

# Title of the window whose geometry exactly matches a picked region, so a
# click-selected window wins over whatever happens to be focused.
hypr_title_for_region() {
	hyprctl -j clients | jq -r --arg region "$1" '
		.[]
		| select("\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" == $region)
		| .title
	' | head -n1
}

# Screenshot filename for a picked region: the clicked window's title when the
# region matches one, otherwise the focused window's.
hypr_region_label() {
	local title file
	title=$(hypr_title_for_region "$1")
	[ -z "$title" ] && title=$(hyprctl activewindow -j | jq -r '.title')

	title="${title% - Visual Studio Code}"
	file="${title% - *}"
	file="${file#● }"

	[ -z "$file" ] && file="screenshot"
	printf '%s\n' "$file"
}
