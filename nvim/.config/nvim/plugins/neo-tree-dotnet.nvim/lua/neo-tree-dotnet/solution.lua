local path = require("neo-tree-dotnet.path")
local tree = require("neo-tree-dotnet.tree")
local M = {}
local SOLUTION_FOLDER_TYPES = {
  ["{66A26720-8FB5-11D2-AA7E-00C04F688DDE}"] = true,
  ["{2150E333-8FDC-42A3-9474-1A3956D46DE8}"] = true,
}

local function node(id, name, kind, file)
  return {
    id = id,
    name = name,
    path = file,
    type = kind == "file" and "file" or "directory",
    loaded = kind ~= "project",
    children = kind ~= "file" and {} or nil,
    extra = { kind = kind },
  }
end

local function project(root, file, name, id)
  local full = path.absolute(file, root.path)
  local result = node(
    root.id .. "::project::" .. (id or full),
    name or vim.fs.basename(full):gsub("%.[^.]+$", ""),
    "project",
    vim.fs.dirname(full)
  )
  result.extra.project_file = full
  result.extra.project_id = result.id
  return result
end

local function file_node(root, parent, file)
  local full = path.absolute(file, root.path)
  return node(parent.id .. "::file::" .. full, vim.fs.basename(full), "file", full)
end

local function parse_sln(root, text)
  assert(text:find("Microsoft Visual Studio Solution File", 1, true), "Invalid SLN header")
  local entries, order, parents = {}, {}, {}
  local current, section
  for line in (text .. "\n"):gmatch("([^\r\n]*)[\r\n]") do
    local kind, name, file, guid = line:match('^%s*Project%s*%(%s*"({[^}]+})"%s*%)%s*=%s*"([^"]*)"%s*,%s*"([^"]*)"%s*,%s*"({[^}]+})"')
    if guid then
      guid = guid:upper()
      assert(not entries[guid], "Duplicate project GUID: " .. guid)
      if SOLUTION_FOLDER_TYPES[kind:upper()] then
        current = node(root.id .. "::folder::" .. guid, name, "solution_folder")
      else
        current = project(root, file, name, guid)
      end
      entries[guid] = current
      order[#order + 1] = guid
      section = nil
    elseif line:match("^%s*EndProject%s*$") then
      current, section = nil, nil
    elseif line:match("ProjectSection%(SolutionItems%)") then
      section = "items"
    elseif line:match("GlobalSection%(NestedProjects%)") then
      section = "nested"
    elseif line:match("^%s*EndProjectSection") or line:match("^%s*EndGlobalSection") then
      section = nil
    elseif section == "items" and current and current.extra.kind == "solution_folder" then
      local item = line:match("^%s*(.-)%s*=%s*.-%s*$")
      if item and item ~= "" then
        table.insert(current.children, file_node(root, current, item))
      end
    elseif section == "nested" then
      local child, parent = line:match("({[^}]+})%s*=%s*({[^}]+})")
      if child then
        parents[child:upper()] = parent:upper()
      end
    end
  end
  for _, guid in ipairs(order) do
    local seen, cursor = {}, guid
    while cursor do
      assert(not seen[cursor], "Cycle in solution folders")
      seen[cursor], cursor = true, parents[cursor]
    end
    local parent = parents[guid] and entries[parents[guid]] or root
    assert(parent and (parent == root or parent.extra.kind == "solution_folder"), "Invalid solution folder parent")
    table.insert(parent.children, entries[guid])
  end
end

local function parse_slnx(root, text)
  local xml = require("neo-tree-dotnet.xml").parse(text)
  assert(xml.name == "Solution", "Expected <Solution> in SLNX")
  local folders, projects = { [""] = root }, {}
  local function folder(name)
    name = name:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "")
    local parent, key = root, ""
    for part in name:gmatch("[^/]+") do
      assert(part ~= "." and part ~= "..", "Invalid solution folder name")
      key = key == "" and part or key .. "/" .. part
      if not folders[key] then
        folders[key] = node(root.id .. "::folder::" .. key, part, "solution_folder")
        table.insert(parent.children, folders[key])
      end
      parent = folders[key]
    end
    return parent
  end
  local function visit(element, parent)
    for _, child in ipairs(element.children) do
      if child.name == "Folder" then
        visit(child, folder(assert(child.attrs.Name, "Folder requires Name")))
      elseif child.name == "Project" then
        local item = project(root, assert(child.attrs.Path, "Project requires Path"), child.attrs.DisplayName)
        assert(not projects[item.id], "Duplicate project path")
        projects[item.id] = true
        table.insert(parent.children, item)
      elseif child.name == "File" then
        table.insert(parent.children, file_node(root, parent, assert(child.attrs.Path, "File requires Path")))
      end
    end
  end
  visit(xml, root)
end

function M.parse(file, text)
  file = path.absolute(file)
  assert(path.is_solution(file), "Expected .sln or .slnx")
  local root = node("solution::" .. file, vim.fs.basename(file), "solution", vim.fs.dirname(file))
  root.extra.solution_file = file
  if file:lower():match("%.slnx$") then
    parse_slnx(root, text)
  else
    parse_sln(root, text)
  end
  tree.sort(root)
  return root
end

function M.load(file)
  return M.parse(file, path.read(file))
end

return M
