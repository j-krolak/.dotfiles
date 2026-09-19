local common = require("neo-tree.sources.common.components")
local M = vim.tbl_extend("force", {}, common)
local icons = { solution = "󰘐", project = "󰌛", solution_folder = "󰉋", dependencies = "󰏖", package = "󰏗" }

function M.icon(config, node, state)
  local icon = icons[(node.extra or {}).kind]
  if icon then
    return { text = icon, highlight = "NeoTreeDirectoryIcon" }
  end
  return common.icon(config, node, state)
end

function M.name(_, node)
  local kind = (node.extra or {}).kind
  local highlight = "NeoTreeFileName"
  if kind == "solution" then
    highlight = "NeoTreeRootName"
  elseif node.type == "directory" then
    highlight = "NeoTreeDirectoryName"
  elseif node.type == "message" then
    highlight = "NeoTreeMessage"
  end
  return { text = node.name, highlight = highlight }
end

return M
