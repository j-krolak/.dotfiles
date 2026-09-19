local path = require("neo-tree-dotnet.path")
local project = require("neo-tree-dotnet.project")
local solution = require("neo-tree-dotnet.solution")
local tree = require("neo-tree-dotnet.tree")
local renderer = require("neo-tree.ui.renderer")

-- One view owns one Neo-tree state's model, lazy requests, and pending reveal.
-- Neo-tree still owns windows, cursor position, and the rendered Nui tree.
local View = {}
View.__index = View

local function message(id, text)
  return { id = id .. "::message", name = text, type = "message", extra = { kind = "message" } }
end

local function loaded_nodes(root, result)
  if not root then
    return result
  end
  if root.loaded then
    result[root.id] = true
  end
  for _, child in ipairs(root.children or {}) do
    loaded_nodes(child, result)
  end
  return result
end

function View.new(state)
  return setmetatable({
    state = state,
    generation = 0,
    pending_expansion = {},
    pending_render = false,
  }, View)
end

function View:is_visible()
  local state = self.state
  if state.disposed or state.tabid ~= vim.api.nvim_get_current_tabpage() then
    return false
  end
  if not state.winid or not vim.api.nvim_win_is_valid(state.winid) then
    return false
  end
  local buffer = vim.api.nvim_win_get_buf(state.winid)
  local ok, source = pcall(vim.api.nvim_buf_get_var, buffer, "neo_tree_source")
  return ok and source == state.name
end

function View:is_current(generation)
  return not self.state.disposed and self.generation == generation
end

-- Invalidate requests from the previous navigation before replacing its model.
function View:begin(file_to_reveal)
  self.generation = self.generation + 1
  self.reveal_file = file_to_reveal and path.absolute(file_to_reveal) or nil
  self.pending_render = false
  self.state.dirty = false
  return self.generation
end

function View:render(initial)
  if not initial and not self:is_visible() then
    return
  end
  local state = self.state
  local editor = vim.api.nvim_get_current_win()
  if not initial then
    state._no_focus = true
    if state.tree and not state.position.node_id then
      renderer.position.save(state, true)
    end
  end
  state.default_expanded_nodes = vim.tbl_keys(self.pending_expansion)
  renderer.show_nodes({ self.root }, state)
  self.pending_render = false
  if not initial and vim.api.nvim_win_is_valid(editor) and vim.api.nvim_get_current_win() ~= editor then
    vim.api.nvim_set_current_win(editor)
  end

  -- Keep expansion requests until lazy children are available to the renderer.
  for id in pairs(self.pending_expansion) do
    local ancestors = tree.find_path(self.root, function(node) return node.id == id end)
    if ancestors and ancestors[#ancestors].loaded then
      self.pending_expansion[id] = nil
    end
  end
  state.default_expanded_nodes = {}
end

function View:show_message(id, text, initial)
  self.root = message(id, text)
  self.pending_expansion = {}
  self:render(initial)
end

function View:_reveal()
  if not self.reveal_file then
    return false
  end
  local ancestors = tree.find_path(self.root, function(node)
    return node.type == "file" and node.path == self.reveal_file
  end)
  if not ancestors then
    return false
  end
  for i = 1, #ancestors - 1 do
    self.pending_expansion[ancestors[i].id] = true
  end
  renderer.position.set(self.state, ancestors[#ancestors].id)
  self.reveal_file = nil
  return true
end

function View:_wants_children(node)
  if not self.reveal_file or node.type ~= "directory" then
    return false
  end
  -- Evaluated projects may own linked files outside their physical directory.
  if node.extra.kind == "project" and self.state.project_files == "msbuild" then
    return true
  end
  return path.contains(node.path, self.reveal_file)
end

function View:_load_children(node, restored)
  if node.loaded or node.extra.loading then
    return
  end
  local generation = self.generation
  node.extra.loading = true
  if node.extra.kind == "project" and self.state.project_files == "msbuild" then
    node.children = { message(node.id, "Evaluating MSBuild…") }
  end
  project.load(node, self.state, function(children, err)
    if not self:is_current(generation) then
      return
    end
    node.extra.loading = nil
    node.loaded = not err
    if err then
      node.children = { message(node.id, "Loading failed — R to retry") }
      vim.notify("neo-tree-dotnet: " .. tostring(err), vim.log.levels.ERROR)
    else
      node.children = children
      self:_restore_children(node, restored)
    end
    self:_reveal()
    self.pending_render = true
    self:render()
  end)
end

-- Restore previously loaded directories and/or the path to the current file.
function View:_restore_children(node, restored)
  if not node.loaded and ((restored and restored[node.id]) or self:_wants_children(node)) then
    self:_load_children(node, restored)
    return
  end
  for _, child in ipairs(node.children or {}) do
    self:_restore_children(child, restored)
  end
end

function View:load(file, initial)
  local state = self.state
  local restored = loaded_nodes(self.root, {})
  self.pending_expansion = {}
  if state.tree then
    for _, id in ipairs(renderer.get_expanded_nodes(state.tree)) do
      self.pending_expansion[id] = true
    end
  end
  local ok, root = pcall(solution.load, file)
  if not ok then
    self:show_message("error", "Cannot read solution — R to retry", initial)
    vim.notify("neo-tree-dotnet: " .. tostring(root), vim.log.levels.ERROR)
    return
  end
  self.solution_file = file
  self.root = root
  state.path = vim.fs.dirname(file)
  self.pending_expansion[root.id] = true
  self:render(initial)
  self:_restore_children(root, restored)
  self:_reveal()
  self:render()
end

function View:follow(file)
  if not self.state.follow_current_file.enabled or not self:is_visible() or not self.root or not file then
    return
  end
  self.reveal_file = path.absolute(file)
  if not self:_reveal() then
    self:_restore_children(self.root)
    self:_reveal()
  end
  self:render()
end

function View:toggle_node()
  local state = self.state
  local current = state.tree and state.tree:get_node()
  if not current or current.type ~= "directory" then
    return
  end
  local ancestors = tree.find_path(self.root, function(node) return node.id == current:get_id() end)
  if not ancestors then
    return
  end
  local node = ancestors[#ancestors]
  if not node.loaded then
    self.pending_expansion[self.root.id] = true
    self.pending_expansion[node.id] = true
    self:_load_children(node)
    self:render()
  else
    if current:is_expanded() then
      current:collapse()
    else
      current:expand()
    end
    renderer.redraw(state)
  end
end

return View
