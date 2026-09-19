# Shared helpers for tagging clipse clipboard-history image entries with a
# custom title. Clipse has no config/CLI option to control the filename it
# assigns to a copied image (always `<filesize>-<timestamp>.png`), so these
# rewrite the entry's display title in clipboard_history.json after the fact.

clipse_history="$HOME/.config/clipse/clipboard_history.json"

clipse_snapshot_image_paths() {
	jq -r '.clipboardHistory[].filePath' "$clipse_history" 2>/dev/null
}

# Waits (up to ~4s) for the new clipse image entry not present in $old_paths
# to appear, then renames it to "📷 $title.png". Run in the background (&)
# after copying the image so the caller doesn't block on clipse's daemon.
clipse_tag_new_image() {
	local old_paths="$1" title="$2"
	local new_path=""

	for _ in $(seq 1 40); do
		sleep 0.1
		new_path=$(jq -r --arg old "$old_paths" '
			($old | split("\n")) as $old_arr
			| [.clipboardHistory[].filePath | select(. != "null" and (. as $p | $old_arr | index($p) | not))][0] // empty
		' "$clipse_history" 2>/dev/null)
		[ -n "$new_path" ] && break
	done
	[ -z "$new_path" ] && return 0

	local tmp_json
	tmp_json=$(mktemp)
	if jq --arg path "$new_path" --arg title "📷 ${title}.png" \
		'(.clipboardHistory[] | select(.filePath == $path) | .value) = $title' \
		"$clipse_history" >"$tmp_json" && [ -s "$tmp_json" ]; then
		mv "$tmp_json" "$clipse_history"
	else
		rm -f "$tmp_json"
	fi
}
