local vars = require("lua.core.variables")

if vars.single_monitor then
	-- Only one real output on this machine: put every workspace on it, or
	-- the ones assigned to the other (nonexistent) monitor can never be
	-- persisted and instead pop in/out of existence as they're switched to.
	for i = 1, 8 do
		hl.workspace_rule({ workspace = tostring(i), monitor = vars.monitors.b, default = true, persistent = true })
	end
else
	for i = 1, 5 do
		hl.workspace_rule({ workspace = tostring(i), monitor = vars.monitors.a, default = true, persistent = true })
	end

	for i = 6, 8 do
		hl.workspace_rule({ workspace = tostring(i), monitor = vars.monitors.b, default = true, persistent = true })
	end
end
