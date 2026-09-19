local path = require("neo-tree-dotnet.path")
local View = require("neo-tree-dotnet.view")
local panel = require("neo-tree-dotnet")

local M = {
  name = "dotnet_solution",
  display_name = " .NET Solution ",
  default_config = require("neo-tree.sources.dotnet_solution.defaults"),
}

-- Registry for live source states; Neo-tree owns their lifetime.
local states = setmetatable({}, { __mode = "k" })
local refresh_versions = setmetatable({}, { __mode = "k" })
local WRITE_DEBOUNCE_MS = 150

local function view_for(state)
  if not state._dotnet then
    state._dotnet = View.new(state)
  end
  states[state] = true
  return state._dotnet
end

local function buffer_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or file:match("^%w+://") then
    return nil
  end
  return path.absolute(file)
end

local function current_file()
  return buffer_file(vim.api.nvim_get_current_buf()) or vim.t.neo_tree_dotnet_file
end

local function selected_solution(state, view, candidates)
  if state.solution then
    return path.absolute(state.solution)
  end
  if view.solution_file and vim.tbl_contains(candidates, view.solution_file) then
    return view.solution_file
  end
  if #candidates == 1 then
    return candidates[1]
  end
end

function M.navigate(state, dir, file_to_reveal, callback)
  local view = view_for(state)
  if not file_to_reveal and state.follow_current_file.enabled then
    file_to_reveal = current_file()
  end
  local generation = view:begin(file_to_reveal)
  state.path = path.absolute(dir or state.path or vim.fn.getcwd())
  local candidates = path.discover(state.path)
  local selected = selected_solution(state, view, candidates)

  if selected then
    view:load(selected, true)
  elseif #candidates == 0 then
    view:show_message("empty", "No .sln/.slnx found — gs to choose a file", true)
  else
    view:show_message("choose", "Choose a solution — gs to select again", true)
    vim.ui.select(candidates, { prompt = "Solution:", format_item = vim.fs.basename }, function(choice)
      if choice and view:is_current(generation) and view:is_visible() then
        view:load(choice, false)
      end
    end)
  end
  if callback then
    vim.schedule(callback)
  end
end

function M.choose_solution(state)
  local candidates = path.discover(state.path or vim.fn.getcwd())
  local function select(file)
    if not file or file == "" or state.disposed then
      return
    end
    state.solution = path.absolute(file)
    M.navigate(state, vim.fs.dirname(state.solution))
  end
  if #candidates > 0 then
    vim.ui.select(candidates, { prompt = "Solution:", format_item = vim.fs.basename }, select)
  else
    vim.ui.input({ prompt = "Solution file: ", completion = "file" }, select)
  end
end

function M.follow(state, file)
  view_for(state):follow(file)
end

function M.toggle_node(state)
  view_for(state):toggle_node()
end

local function on_write(args)
  if args.file == "" then
    return
  end
  for state in pairs(states) do
    local view = state._dotnet
    if not state.disposed and view.root then
      state.dirty = true
      refresh_versions[state] = (refresh_versions[state] or 0) + 1
      local version = refresh_versions[state]
      vim.defer_fn(function()
        if version == refresh_versions[state] and view:is_visible() then
          M.navigate(state, state.path)
        end
      end, WRITE_DEBOUNCE_MS)
    end
  end
end

local function on_enter()
  local buf = vim.api.nvim_get_current_buf()
  local tab = vim.api.nvim_get_current_tabpage()
  local file = buffer_file(buf)
  if file then
    vim.t.neo_tree_dotnet_file = file
  end

  vim.schedule(function()
    -- Ignore stale events after a newer buffer/tab switch.
    if vim.api.nvim_get_current_tabpage() ~= tab or vim.api.nvim_get_current_buf() ~= buf then
      return
    end
    local state = require("neo-tree.sources.manager").get_state_for_window()
    if state then
      panel.remember(state)
    end
    if state and state.name == M.name then
      local view = view_for(state)
      if view:is_visible() then
        if state.dirty then
          M.navigate(state, state.path)
        elseif view.pending_render then
          view:render()
        end
      end
    elseif file then
      for candidate in pairs(states) do
        candidate._dotnet:follow(file)
      end
    end
  end)
end

function M.setup(config)
  assert(
    config.project_files == "filesystem" or config.project_files == "msbuild",
    "Invalid dotnet_solution.project_files"
  )
  panel.setup_tracking()
  local group = vim.api.nvim_create_augroup("NeoTreeDotnet", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", { group = group, callback = on_write })
  vim.api.nvim_create_autocmd({ "BufEnter", "TabEnter" }, { group = group, callback = on_enter })
end

return M
