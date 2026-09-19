-- "Minimal mode" - strips the desktop chrome: the bar goes away and the outer
-- gap opens up, so a window has the screen to itself.
--
-- That's all it does. The presentation aids - the ring under the cursor and the
-- click ripples - are core/presenting.lua, on their own shortcut, because
-- wanting a clean screen to work in and wanting an audience to follow your
-- pointer are different occasions.
--
-- Quickshell's Bar.qml watches this via the custom IPC event below
-- ("custom>>minimal,mode on|off" on socket2) and hides itself.

local M = {}

local GAPS_OUT = 30  -- outer gap while minimal: with the bar gone the windows
                     -- would otherwise sit flush against the screen edge

-- Read rather than hardcoded, so core/options.lua stays the one place the normal
-- gap is defined. Safe because options.lua is required before this file.
local baseGapsOut = (hl.get_config("general.gaps_out") or {}).top or 10

local active = false

function M.is_active() return active end

function M.start()
	if active then return end
	active = true

	hl.config({ general = { gaps_out = GAPS_OUT } })
	hl.dispatch(hl.dsp.event("minimal,mode on"))
end

function M.stop()
	if not active then return end
	active = false

	hl.config({ general = { gaps_out = baseGapsOut } })
	hl.dispatch(hl.dsp.event("minimal,mode off"))
end

function M.toggle()
	if active then M.stop() else M.start() end
end

return M
