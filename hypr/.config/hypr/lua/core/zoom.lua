-- The magnifier: Hyprland's cursor:zoom_factor, driven as a ramp rather than in
-- steps, plus the choice of how its camera pans.
--
-- Deliberately independent of both minimal and presenting mode. Nudging the zoom
-- shouldn't tear the bar away mid-task, and presenting shouldn't force a zoom
-- level on you - the modes are their own shortcuts.

local M = {}

local ZOOM_MAX    = 5.0
local ZOOM_RATE   = 2.2   -- factor per second while a zoom key is held down
local RAMP_PERIOD = 16    -- ms per ramp step (~60Hz)

local ramp
local rampDirection = 0
-- Tracked rather than read back per step: get_config returns the *animated*
-- zoom, which lags the target, so ramping off it would fight the animation and
-- crawl to a halt.
local target = 1

-- Which of Hyprland's camera behaviours to use depends on whether the
-- smooth-zoom plugin (plugins/smooth-zoom) is loaded, because the plugin
-- changes what "rigid" means:
--
--   without it   detached, i.e. a 90% dead zone and then 1:1 scrolling. Rigid
--                would lock the view to every twitch of the mouse.
--   with it      attached + rigid, where the plugin has replaced the camera's
--                target with one that keeps a small dead zone and then eases
--                after the cursor instead of scrolling with it.
--
-- Re-checked whenever a zoom starts, so loading the plugin and zooming is
-- enough; no config reload needed.
local function applyCameraMode()
	local smooth = false
	for _, plugin in ipairs(hl.get_loaded_plugins() or {}) do
		if plugin.name == "smooth-zoom" then smooth = true break end
	end

	hl.config({ cursor = {
		zoom_detached_camera = not smooth,
		zoom_rigid           = smooth,
	} })
end

function M.is_zoomed() return target > 1 end

function M.set(factor)
	target = math.max(1, math.min(ZOOM_MAX, factor))
	hl.config({ cursor = { zoom_factor = target } })
end

-- Held down rather than tapped: key repeat would give a stepped zoom, gated
-- behind the repeat delay. This ramps continuously from the moment the key goes
-- down. Exponential because zoom is multiplicative - a flat step per tick
-- crawls at 4x and lurches at 1.1x.
local function rampStep()
	local step = ZOOM_RATE ^ (RAMP_PERIOD / 1000)
	M.set(rampDirection > 0 and target * step or target / step)
end

function M.hold(direction)
	applyCameraMode()
	rampDirection = direction
	rampStep()
	ramp:set_enabled(true)
end

function M.release()
	ramp:set_enabled(false)
	-- Anything below this reads as a rendering glitch rather than a zoom, and
	-- leaves the screen subtly soft for no reason.
	if target < 1.05 then M.set(1) end
end

function M.reset()
	ramp:set_enabled(false)
	M.set(1)
end

ramp = hl.timer(rampStep, { timeout = RAMP_PERIOD, type = "repeat" })
ramp:set_enabled(false)

applyCameraMode()

return M
