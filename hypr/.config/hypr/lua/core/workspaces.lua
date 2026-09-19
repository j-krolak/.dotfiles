local vars = require("lua.core.variables")

for i = 1, 5 do
	hl.workspace_rule({ workspace = tostring(i), monitor = vars.monitors.a, default = true, persistent = true })
end

for i = 6, 8 do
	hl.workspace_rule({ workspace = tostring(i), monitor = vars.monitors.b, default = true, persistent = true })
end
