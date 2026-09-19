local M = {}

-- Global convenience: hl.exec("cmd") == hl.dsp.exec_cmd("cmd"). Set here,
-- required once from hyprland.lua, so every file can call hl.exec(...)
-- directly without requiring this module.
function hl.exec(cmd)
	return hl.dsp.exec_cmd(cmd)
end

-- Appends entries from `items` onto `list`, returns `list`.
function M.extend(list, items)
	for _, item in ipairs(items) do
		table.insert(list, item)
	end
	return list
end

-- Two keymap entries for the same name/action, bound under both ALT+CTRL and
-- ALT+SHIFT (two-handed access to one action).
function M.dual(name, key, action, opts)
	return {
		{ name = name, keymap = "ALT + CTRL + " .. key,  action = action, opts = opts },
		{ name = name, keymap = "ALT + SHIFT + " .. key, action = action, opts = opts },
	}
end

return M
