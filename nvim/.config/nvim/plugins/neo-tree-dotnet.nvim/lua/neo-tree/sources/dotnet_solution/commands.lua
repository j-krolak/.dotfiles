local common = require("neo-tree.sources.common.commands")
local M = {}
for _, name in ipairs({
  "close_node", "close_all_nodes", "close_all_subnodes", "close_window",
  "next_source", "prev_source", "show_help",
}) do
  M[name] = common[name]
end

function M.toggle_node(state)
  require("neo-tree.sources.dotnet_solution").toggle_node(state)
end

local function open(state, command)
  local node = state.tree and state.tree:get_node()
  if not node then
    return
  end
  if node.type == "directory" then
    M.toggle_node(state)
  elseif node.type == "file" and node.path then
    require("neo-tree.utils").open_file(state, node.path, command)
  end
end

function M.open(state)
  open(state, "edit")
end

function M.open_split(state)
  open(state, "split")
end

function M.open_vsplit(state)
  open(state, "vsplit")
end

function M.open_tabnew(state)
  open(state, "tabnew")
end

function M.open_definition(state)
  local node = state.tree and state.tree:get_node()
  local extra = node and node.extra or {}
  local file = extra.project_file or extra.solution_file
  if file then
    require("neo-tree.utils").open_file(state, file, "edit")
  end
end

function M.refresh(state)
  require("neo-tree.sources.dotnet_solution").navigate(state, state.path)
end

function M.choose_solution(state)
  require("neo-tree.sources.dotnet_solution").choose_solution(state)
end

function M.switch_view()
  require("neo-tree-dotnet").toggle()
end

return M
