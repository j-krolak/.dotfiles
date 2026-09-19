local count = 0
local function test(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    io.stderr:write("FAIL " .. name .. "\n" .. err .. "\n")
    vim.cmd("cquit 1")
  end
  count = count + 1
  print("PASS " .. name)
end
local function eq(expected, actual)
  assert(vim.deep_equal(expected, actual), "Expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local root = vim.fn.getcwd()
local fixtures = root .. "/tests/fixtures"
local solution = require("neo-tree-dotnet.solution")
local paths = require("neo-tree-dotnet.path")
local function search(item, predicate)
  if predicate(item) then return item end
  for _, child in ipairs(item.children or {}) do
    local result = search(child, predicate)
    if result then return result end
  end
end
local function named(item, name)
  return search(item, function(node) return node.name == name end)
end

test("SLN logical folders, projects, solution items and Windows separators", function()
  local tree = solution.load(fixtures .. "/Demo.sln")
  eq("Api", named(tree, "Backend").children[1].name)
  eq(fixtures .. "/Api/Api.csproj", named(tree, "Api").extra.project_file)
  eq(fixtures .. "/README.md", named(tree, "README.md").path)
  eq(false, named(tree, "Api").loaded)
end)

test("SLNX reconstructs nested logical folders", function()
  local tree = solution.load(fixtures .. "/Demo.slnx")
  eq("Services", named(tree, "Backend").children[1].name)
  eq("Api", named(tree, "Services").children[1].name)
end)

test("XML supports quoting, Unicode entities and comments", function()
  local tree = solution.parse(fixtures .. "/Escaped.slnx", [[<Solution><!-- <Folder Name="ignored"/> --><Folder Name='/A &amp; B &#x141;/'>
    <Project Path='Api/Api.csproj' DisplayName='Api &gt; Core' /></Folder></Solution>]])
  eq("Api > Core", named(tree, "A & B Ł").children[1].name)
end)

test("Malformed XML and cyclic SLN fail clearly", function()
  eq(false, pcall(solution.parse, "bad.slnx", "<Solution><Folder></Solution>"))
  eq(false, pcall(solution.parse, "bad.slnx", '<!DOCTYPE Solution SYSTEM "file:///etc/passwd"><Solution/>'))
  local text = paths.read(fixtures .. "/Demo.sln")
  text = text:gsub("{33333333%-3333%-3333%-3333%-333333333333} = {11111111%-1111%-1111%-1111%-111111111111}",
    "{11111111-1111-1111-1111-111111111111} = {11111111-1111-1111-1111-111111111111}")
  eq(false, pcall(solution.parse, "bad.sln", text))
end)

test("Discovery finds nearest ancestor and sorts multiple solutions", function()
  eq({ fixtures .. "/Demo.sln", fixtures .. "/Demo.slnx" }, paths.discover(fixtures .. "/Api/Controllers"))
end)

local neo = require("neo-tree")
neo.setup({
  sources = { "filesystem", "dotnet_solution" },
  enable_git_status = false, enable_diagnostics = false,
  filesystem = { bind_to_cwd = false },
  source_selector = { winbar = true, sources = {
    { source = "filesystem", display_name = " Files " },
    { source = "dotnet_solution", display_name = " Solution " },
  } },
  dotnet_solution = { solution = fixtures .. "/Demo.slnx" },
})
vim.cmd("runtime plugin/neo-tree-dotnet.lua")
local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")
local api = require("neo-tree-dotnet")
local function await_source(name)
  local ready = vim.wait(3000, function()
    local active = manager.get_state_for_window()
    return active and active.name == name
  end, 10)
  if not ready then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      print(vim.inspect({ win = win, current = vim.api.nvim_get_current_win(), buffer = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), vars = vim.fn.getbufvar(vim.api.nvim_win_get_buf(win), "") }))
    end
    local fs = manager.get_state("filesystem")
    print(vim.inspect({ path = fs.path, loading = fs.loading, tree = fs.tree ~= nil, ready = fs._ready, winid = fs.winid }))
  end
  assert(ready, "Source did not become active: " .. name)
end
local commands = require("neo-tree.sources.dotnet_solution.commands")
local state
local function focus(name)
  local item = assert(named(state._dotnet.root, name), "Missing node " .. name)
  local node = assert(state.tree:get_node(item.id))
  local parent = node:get_parent_id()
  while parent do
    local parent_node = state.tree:get_node(parent)
    parent_node:expand()
    parent = parent_node:get_parent_id()
  end
  renderer.redraw(state)
  renderer.focus_node(state, item.id)
  return item
end

test("Real Neo-tree renders the custom source and selector", function()
  api.open()
  state = manager.get_state("dotnet_solution")
  assert(state.tree and vim.api.nvim_win_is_valid(state.winid))
  eq("dotnet_solution", manager.get_state_for_window().name)
  assert(table.concat(vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false), "\n"):find("Demo.slnx", 1, true))
end)

test("Lazy project and folder expansion opens the physical file", function()
  focus("Api")
  commands.open(state)
  eq(true, named(state._dotnet.root, "Api").loaded)
  focus("Controllers")
  commands.open(state)
  focus("Example.cs")
  commands.open(state)
  eq(fixtures .. "/Api/Controllers/Example.cs", vim.api.nvim_buf_get_name(0))
end)

test("Toggle from editor switches both ways without changing cwd", function()
  local cwd = vim.fn.getcwd()
  api.toggle()
  await_source("filesystem")
  eq("filesystem", manager.get_state_for_window().name)
  api.toggle()
  await_source("dotnet_solution")
  eq("dotnet_solution", manager.get_state_for_window().name)
  eq(cwd, vim.fn.getcwd())
  assert(named(state._dotnet.root, "Example.cs"), "Loaded descendants lost on switch")
end)

test("Refresh keeps loaded project directories and expansion", function()
  focus("Controllers")
  state.tree:get_node():expand()
  commands.refresh(state)
  assert(named(state._dotnet.root, "Example.cs"))
  assert(state.tree:get_node(named(state._dotnet.root, "Controllers").id):is_expanded())
end)

test("Project definition opens csproj", function()
  focus("Api")
  commands.open_definition(state)
  eq(fixtures .. "/Api/Api.csproj", vim.api.nvim_buf_get_name(0))
  api.open()
end)

test("Reveal maps a physical path to the logical node ID", function()
  require("neo-tree.sources.dotnet_solution").navigate(state, fixtures, fixtures .. "/Api/Controllers/Example.cs")
  eq("Example.cs", state.tree:get_node().name)
end)

local function selected_file()
  if not renderer.window_exists(state) then return nil end
  local row = vim.api.nvim_win_get_cursor(state.winid)[1]
  local node = state.tree:get_node(row)
  return node and node.path
end

local function edit_file(file)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not manager.get_state_for_window(win) then
      vim.api.nvim_set_current_win(win)
      break
    end
  end
  vim.cmd.edit(vim.fn.fnameescape(file))
  return vim.api.nvim_get_current_win()
end

test("Following an editor buffer loads and expands lazy ancestors without taking focus", function()
  -- Let Neo-tree's 100ms filesystem navigation debounce from the prior source
  -- switching tests settle before starting this independent editor-event case.
  vim.wait(200, function() return false end, 10)
  state.follow_current_file.enabled = false
  state._dotnet.root = nil
  require("neo-tree.sources.dotnet_solution").navigate(state, fixtures)
  eq(false, named(state._dotnet.root, "Api").loaded)
  state.follow_current_file.enabled = true
  local target = fixtures .. "/Api/Controllers/Example.cs"
  local editor = edit_file(target)
  vim.api.nvim_win_set_cursor(editor, { 2, 0 })
  local followed = vim.wait(1000, function() return selected_file() == target end, 10)
  if not followed then
    print(vim.inspect({ selected = selected_file(), target = target, current = vim.api.nvim_buf_get_name(0),
      remembered = vim.t.neo_tree_dotnet_file, pending = state._dotnet.reveal_file,
      loaded = named(state._dotnet.root, "Api").loaded, node = named(state._dotnet.root, "Example.cs"),
      window = state.winid, buf = state.bufnr, winbuf = vim.api.nvim_win_get_buf(state.winid),
      lines = vim.api.nvim_buf_get_lines(state.bufnr, 0, -1, false), expanded = renderer.get_expanded_nodes(state.tree),
      tree_cursor = vim.api.nvim_win_get_cursor(state.winid) }))
  end
  assert(followed, "Active file not followed")
  eq(editor, vim.api.nvim_get_current_win())
  eq({ 2, 0 }, vim.api.nvim_win_get_cursor(editor))
  for _, name in ipairs({ "Backend", "Services", "Api", "Controllers" }) do
    assert(state.tree:get_node(named(state._dotnet.root, name).id):is_expanded(), name .. " not expanded")
  end
end)

test("Following changes selection between already loaded files without rebuilding the solution", function()
  local model = state._dotnet.root
  local target = fixtures .. "/Api/Program.cs"
  local editor = edit_file(target)
  assert(vim.wait(1000, function() return selected_file() == target end, 10))
  eq(editor, vim.api.nvim_get_current_win())
  assert(model == state._dotnet.root, "Follow should reuse the model")
end)

test("Following ignores unrelated files and can be disabled", function()
  local selected, model = selected_file(), state._dotnet.root
  edit_file(root .. "/README.md")
  local drained = false
  vim.schedule(function() drained = true end)
  assert(vim.wait(1000, function() return drained end, 10))
  eq(selected, selected_file())
  assert(model == state._dotnet.root)
  state.follow_current_file.enabled = false
  edit_file(fixtures .. "/Api/Controllers/Example.cs")
  drained = false
  vim.schedule(function() drained = true end)
  assert(vim.wait(1000, function() return drained end, 10))
  eq(selected, selected_file())
  state.follow_current_file.enabled = true
end)

test("Hidden solution stays hidden; reopening follows the latest editor file", function()
  require("neo-tree.command").execute({ action = "close", source = "dotnet_solution" })
  local target = fixtures .. "/Api/Program.cs"
  edit_file(target)
  local drained = false
  vim.schedule(function() drained = true end)
  assert(vim.wait(1000, function() return drained end, 10))
  eq(false, renderer.window_exists(state))
  api.open()
  eq(target, selected_file())
end)

test("Evaluated model deduplicates items and keeps duplicate basenames distinct", function()
  local p = named(state._dotnet.root, "Api")
  local children = require("neo-tree-dotnet.project").from_items(p, { Items = {
    Compile = {
      { FullPath = fixtures .. "/Shared/Linked.cs", Link = "Common/Linked.cs" },
      { FullPath = "/external/one/Foo.cs" }, { FullPath = "/external/two/Foo.cs" },
    },
    None = { { FullPath = fixtures .. "/Shared/Linked.cs", Link = "Common/Linked.cs" } },
  } })
  local tree = { children = children }
  eq(1, #named(tree, "Common").children)
  local external = named(tree, "External").children
  eq(2, #external)
  assert(external[1].id ~= external[2].id)
end)

test("Actual MSBuild respects Remove, linked files and package versions", function()
  assert(vim.fn.executable("dotnet") == 1, "dotnet SDK 8+ needed for integration tests")
  local p = named(state._dotnet.root, "Api")
  local done, result, error_message = false, nil, nil
  require("neo-tree-dotnet.project").evaluate(p, state, function(children, err)
    done, result, error_message = true, children, err
  end)
  assert(vim.wait(35000, function() return done end, 10), "MSBuild timed out")
  assert(result, error_message)
  local tree = { children = result }
  assert(named(tree, "Program.cs"))
  assert(not named(tree, "Excluded.cs"))
  eq(fixtures .. "/Shared/Linked.cs", named(tree, "Common").children[1].path)
  assert(named(tree, "Example.Package (1.2.3)"))
end)

test("Async completion cannot reopen a panel switched to filesystem", function()
  local project_module = require("neo-tree-dotnet.project")
  local evaluate = project_module.evaluate
  local deferred
  project_module.evaluate = function(_, _, cb) deferred = cb end
  state.project_files = "msbuild"
  commands.refresh(state)
  assert(deferred)
  api.toggle()
  await_source("filesystem")
  deferred({ { id = "late-result", name = "Late.cs", type = "file", path = "/Late.cs" } })
  eq("filesystem", manager.get_state_for_window().name)
  project_module.evaluate = evaluate
  state.project_files = "filesystem"
end)

test("Missing solutions show a useful empty state", function()
  state.solution, state._dotnet.solution_file = nil, nil
  require("neo-tree.sources.dotnet_solution").navigate(state, root)
  eq("message", state._dotnet.root.type)
  assert(state._dotnet.root.name:find("No .sln/.slnx", 1, true))
end)

test("Multiple-solution selection and cancellation", function()
  local original = vim.ui.select
  local choices
  vim.ui.select = function(items, _, cb) choices = items; cb(nil) end
  require("neo-tree.sources.dotnet_solution").navigate(state, fixtures)
  eq(2, #choices)
  eq("message", state._dotnet.root.type)
  vim.ui.select = function(items, _, cb) cb(items[1]) end
  require("neo-tree.sources.dotnet_solution").navigate(state, fixtures)
  eq("Demo.sln", state._dotnet.root.name)
  vim.ui.select = original
end)

test("Panel source memory is independent of commands in another tab", function()
  vim.wait(200, function() return false end, 10)
  api.open(fixtures .. "/Demo.slnx")
  local first = vim.api.nvim_get_current_tabpage()
  local position = manager.get_state_for_window().current_position
  api.toggle_panel()
  eq(false, renderer.window_exists(state))
  vim.cmd("tabnew")
  local second = vim.api.nvim_get_current_tabpage()
  require("neo-tree.command").execute({ source = "filesystem", dir = fixtures, position = "right" })
  await_source("filesystem")
  vim.wait(200, function() return false end, 10)
  api.toggle_panel()
  vim.api.nvim_set_current_tabpage(first)
  api.toggle_panel()
  await_source("dotnet_solution")
  eq(position, manager.get_state_for_window().current_position)
  eq(fixtures .. "/Demo.slnx", state._dotnet.solution_file)
  vim.api.nvim_set_current_tabpage(second)
  api.toggle_panel()
  await_source("filesystem")
  eq("right", manager.get_state_for_window().current_position)
  vim.wait(200, function() return false end, 10)
  vim.cmd("tabclose")
  eq(first, vim.api.nvim_get_current_tabpage())
end)

test("Native selector choice survives external close and repeated panel toggles", function()
  vim.wait(200, function() return false end, 10)
  api.open(fixtures .. "/Demo.slnx")
  local win = manager.get_state_for_window().winid
  local base = #require("neo-tree").config.source_selector.sources + 1
  _G.___neotree_selector_click(base * win + 1, 1, "l", "")
  await_source("filesystem")
  vim.wait(200, function() return false end, 10)
  require("neo-tree.command").execute({ action = "close" })
  eq("filesystem", vim.t.neo_tree_dotnet_panel.source)
  for _ = 1, 3 do
    api.toggle_panel()
    await_source("filesystem")
    vim.wait(200, function() return false end, 10)
    api.toggle_panel()
    eq(false, renderer.window_exists(manager.get_state("filesystem")))
  end
end)

test("An evaluation completed after refresh cannot replace the new view", function()
  api.open(fixtures .. "/Demo.slnx")
  local project_module = require("neo-tree-dotnet.project")
  local evaluate = project_module.evaluate
  local callbacks = {}
  project_module.evaluate = function(_, _, callback)
    callbacks[#callbacks + 1] = callback
  end
  state.project_files = "msbuild"
  state.follow_current_file.enabled = false
  state._dotnet.root = nil
  commands.refresh(state)
  focus("Api")
  commands.open(state)
  commands.refresh(state)
  focus("Api")
  commands.open(state)
  eq(2, #callbacks)
  local current = state._dotnet.root
  callbacks[1]({ { id = "stale", name = "Stale.cs", type = "file" } })
  assert(current == state._dotnet.root)
  assert(not named(current, "Stale.cs"))
  callbacks[2]({ { id = "fresh", name = "Fresh.cs", type = "file" } })
  assert(named(current, "Fresh.cs"))
  project_module.evaluate = evaluate
  state.project_files = "filesystem"
  state.follow_current_file.enabled = true
  commands.refresh(state)
end)

test("Space waits for leader combinations in Solution", function()
  api.open(fixtures .. "/Demo.slnx")
  local space = vim.fn.maparg("<Space>", "n", false, true)
  eq(1, space.buffer)
  eq(0, space.nowait)
end)

print(string.format("\n%d tests passed", count))
vim.cmd("qa!")
