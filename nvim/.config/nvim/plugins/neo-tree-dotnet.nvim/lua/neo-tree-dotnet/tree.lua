local M = {}

-- Return model nodes from the root to the first matching node. File paths and
-- logical node IDs are intentionally separate (a linked file can appear twice).
function M.find_path(root, matches)
  local ancestors = {}
  local function visit(node)
    ancestors[#ancestors + 1] = node
    if matches(node) then
      return true
    end
    for _, child in ipairs(node.children or {}) do
      if visit(child) then
        return true
      end
    end
    table.remove(ancestors)
    return false
  end

  if root and visit(root) then
    return ancestors
  end
end

function M.sort(root)
  table.sort(root.children or {}, function(a, b)
    if a.type ~= b.type then
      return a.type == "directory"
    end
    if a.name:lower() ~= b.name:lower() then
      return a.name:lower() < b.name:lower()
    end
    return a.id < b.id
  end)
  for _, child in ipairs(root.children or {}) do
    M.sort(child)
  end
end

return M
