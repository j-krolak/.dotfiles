-- "Presenting mode" - the bits that exist for an audience rather than for you:
-- a ring marking where the cursor is, a ripple at every click, and a cursor that
-- stops auto-hiding mid-sentence.
--
-- Separate from core/minimal.lua on purpose. Minimal is about clearing the
-- screen; this is about making a pointer easy to follow, and you don't always
-- want both.
--
-- The drawing all happens in Quickshell (modules/PresentOverlay.qml); this file
-- only decides when the mode is on and feeds it a cursor position stream plus
-- click events. Both travel as Hyprland custom IPC events ("custom>>present,..."
-- on socket2), which Quickshell already listens to via Hyprland.rawEvent, so no
-- fifo or extra socket is involved.

local M = {}

local CURSOR_PERIOD = 8  -- ms between cursor samples. The ring is pinned to the
                         -- cursor rather than eased toward it, so sampling
                         -- slower than the display shows up as rubber-banding
                         -- on fast flicks.
local BUTTONS       = { 272, 273, 274 } -- left, right, middle

local active = false
local clickBinds = {}
local cursorTimer

local function emit(payload)
	hl.dispatch(hl.dsp.event("present," .. payload))
end

local function sampleCursor()
	local p = hl.get_cursor_pos()
	if p then emit(string.format("cursor %.1f %.1f", p.x, p.y)) end
end

function M.is_active() return active end

function M.start()
	if active then return end
	active = true

	-- A cursor that fades out while you're still talking about what it's
	-- pointing at is useless.
	hl.config({ cursor = { inactive_timeout = 0 } })

	for _, b in ipairs(clickBinds) do b:set_enabled(true) end
	cursorTimer:set_enabled(true)
	emit("mode on")
end

function M.stop()
	if not active then return end
	active = false

	hl.config({ cursor = { inactive_timeout = 3 } })

	for _, b in ipairs(clickBinds) do b:set_enabled(false) end
	cursorTimer:set_enabled(false)
	emit("mode off")
end

function M.toggle()
	if active then M.stop() else M.start() end
end

-- Registered once, disabled, and only switched on in presenting mode: a mouse
-- bind that misbehaves should not be able to eat clicks the rest of the time.
-- non_consuming is what lets the click still reach the window underneath.
for i, button in ipairs(BUTTONS) do
	local bind = hl.bind("mouse:" .. button, function()
		local p = hl.get_cursor_pos()
		if p then emit(string.format("click %.1f %.1f %d", p.x, p.y, button)) end
	end, { non_consuming = true })
	bind:set_enabled(false)
	clickBinds[i] = bind
end

cursorTimer = hl.timer(sampleCursor, { timeout = CURSOR_PERIOD, type = "repeat" })
cursorTimer:set_enabled(false)

return M
