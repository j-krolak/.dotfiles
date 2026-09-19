local M = {}

local function visible_state()
  local manager = require("neo-tree.sources.manager")
  local state = manager.get_state_for_window()
  if not state then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local candidate = manager.get_state_for_window(win)
      if candidate then
        state = candidate
        break
      end
    end
  end
  return state
end

-- Own the preference per tab instead of using neo-tree.command._last, which is
-- global and describes the last command, not necessarily this tab's last panel.
function M.remember(state)
  local tab = state.tabid or vim.api.nvim_get_current_tabpage()
  if not vim.api.nvim_tabpage_is_valid(tab) then
    return
  end
  local source = state.name or state.source
  if not source then
    return
  end
  vim.api.nvim_tabpage_set_var(tab, "neo_tree_dotnet_panel", {
    source = source,
    position = state.current_position
      or (type(state.position) == "string" and state.position)
      or (state.window and state.window.position),
  })
end

function M.setup_tracking()
  local events = require("neo-tree.events")
  for _, event in ipairs({ events.NEO_TREE_WINDOW_AFTER_OPEN, events.NEO_TREE_WINDOW_BEFORE_CLOSE }) do
    events.subscribe({ id = "neo-tree-dotnet.remember." .. event, event = event, handler = M.remember })
  end
end

-- Hide/show only. Switching the view is a separate operation (toggle / Tab).
function M.toggle_panel()
  local state = visible_state()
  local command = require("neo-tree.command")
  if state then
    M.remember(state)
    command.execute({ action = "close", source = state.name, position = state.current_position })
    return
  end
  local saved = vim.t.neo_tree_dotnet_panel or { source = "filesystem" }
  local target = require("neo-tree.sources.manager").get_state(saved.source)
  command.execute({
    action = "focus",
    source = saved.source,
    position = saved.position or target.window.position,
    dir = target.path,
  })
end

-- Usable from the panel or editor; the visible source takes precedence.
function M.toggle()
  local manager = require("neo-tree.sources.manager")
  local state = visible_state()
  local saved = vim.t.neo_tree_dotnet_panel or {}
  local current = state and state.name or saved.source
  local source = current == "dotnet_solution" and "filesystem" or "dotnet_solution"
  local dir = state and state.path or nil
  -- Neo-tree may reuse the sidebar without focusing it when switching sources.
  if state and state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.api.nvim_set_current_win(state.winid)
  end
  require("neo-tree.command").execute({
    action = "focus",
    source = source,
    position = state and state.current_position or manager.get_state(source).window.position,
    dir = dir,
  })
end

function M.open(solution)
  local state = require("neo-tree.sources.manager").get_state("dotnet_solution")
  if solution and solution ~= "" then
    solution = require("neo-tree-dotnet.path").absolute(solution)
    state.solution = solution
    state.path = vim.fs.dirname(solution)
    state.dirty = true
  end
  require("neo-tree.command").execute({ source = "dotnet_solution", action = "focus", dir = state.path })
end

return M
