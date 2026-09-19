local path = require("neo-tree-dotnet.path")
local tree = require("neo-tree-dotnet.tree")
local msbuild = require("neo-tree-dotnet.msbuild")
local uv = vim.uv or vim.loop
local M = {}

local function file_node(project_id, file, name, logical)
  return {
    id = project_id .. "::file::" .. (logical or file),
    name = name or vim.fs.basename(file),
    path = file,
    type = "file",
    ext = file:match("%.([^./]+)$"),
    extra = { kind = "file", project_id = project_id },
  }
end

-- A single directory is scanned only when expanded. Symlink directories are
-- omitted to avoid loops; symlink files can still be opened.
function M.scan(parent, options)
  local scan, err = uv.fs_scandir(parent.path)
  assert(scan, err)
  local excluded = {}
  for _, name in ipairs(options.excluded_dirs) do
    excluded[name] = true
  end
  local children = {}
  local project_id = parent.extra.project_id
  while true do
    local name, kind = uv.fs_scandir_next(scan)
    if not name then
      break
    end
    local full = path.absolute(name, parent.path)
    if kind == "link" then
      local stat = uv.fs_stat(full)
      kind = stat and stat.type == "file" and "file" or "skip"
    end
    if kind == "directory" and not excluded[name] then
      children[#children + 1] = {
        id = project_id .. "::dir::" .. full,
        name = name,
        path = full,
        type = "directory",
        loaded = false,
        children = {},
        extra = { kind = "physical_directory", project_id = project_id },
      }
    elseif kind == "file" then
      children[#children + 1] = file_node(project_id, full)
    end
  end
  local wrapper = { children = children }
  tree.sort(wrapper)
  return children
end

function M.from_items(project, data)
  local root = { children = {} }
  local folders, seen = { [""] = root }, {}
  local function insert(file, logical)
    logical = (logical or vim.fs.basename(file)):gsub("\\", "/"):gsub("^%./", "")
    -- External items without Link metadata are placed in a virtual folder.
    if logical:match("^/") or logical:match("^%a:") or ("/" .. logical .. "/"):find("/../", 1, true) then
      logical = "External/" .. vim.fs.basename(file)
    end
    local dedup = logical .. "\0" .. file
    if seen[dedup] then
      return
    end
    seen[dedup] = true
    local parts = vim.split(logical, "/", { trimempty = true })
    local parent, key = root, ""
    for i = 1, #parts - 1 do
      key = key == "" and parts[i] or key .. "/" .. parts[i]
      if not folders[key] then
        folders[key] = {
          id = project.id .. "::logical::" .. key,
          name = parts[i],
          type = "directory",
          loaded = true,
          children = {},
          extra = { kind = "logical_directory" },
        }
        table.insert(parent.children, folders[key])
      end
      parent = folders[key]
    end
    table.insert(parent.children, file_node(project.id, file, parts[#parts], logical .. "::" .. file))
  end
  insert(project.extra.project_file, vim.fs.basename(project.extra.project_file))
  for _, kind in ipairs(msbuild.item_types) do
    for _, item in ipairs((data.Items or {})[kind] or {}) do
      local file = path.absolute(item.FullPath or item.Identity, project.path)
      local relative = path.contains(project.path, file) and file:sub(#project.path + 2) or file
      insert(file, item.Link ~= "" and item.Link or relative)
    end
  end
  local dependencies = {
    id = project.id .. "::dependencies",
    name = "Dependencies",
    type = "directory",
    loaded = true,
    children = {},
    extra = { kind = "dependencies" },
  }
  for _, item in ipairs((data.Items or {}).ProjectReference or {}) do
    local file = path.absolute(item.FullPath or item.Identity, project.path)
    table.insert(dependencies.children, file_node(project.id .. "::references", file))
  end
  for _, item in ipairs((data.Items or {}).PackageReference or {}) do
    local version = item.VersionOverride or item.Version
    if not version or version == "" then
      for _, central in ipairs((data.Items or {}).PackageVersion or {}) do
        if central.Identity == item.Identity then
          version = central.Version
        end
      end
    end
    table.insert(dependencies.children, {
      id = project.id .. "::package::" .. item.Identity,
      name = item.Identity .. (version and version ~= "" and " (" .. version .. ")" or ""),
      type = "message",
      extra = { kind = "package" },
    })
  end
  if #dependencies.children > 0 then
    table.insert(root.children, dependencies)
  end
  tree.sort(root)
  return root.children
end

-- Translate evaluated data at the project seam. The view uses the same callback
-- shape for physical directories and evaluated project content.
function M.evaluate(project, options, callback)
  msbuild.read(project.extra.project_file, options, function(data, err)
    if not data then
      callback(nil, err)
      return
    end
    local ok, children = pcall(M.from_items, project, data)
    if ok then
      callback(children)
    else
      callback(nil, children)
    end
  end)
end

function M.load(node, options, callback)
  if node.extra.kind == "project" and options.project_files == "msbuild" then
    M.evaluate(node, options, callback)
    return
  end
  local ok, children = pcall(M.scan, node, options)
  if ok then
    callback(children)
  else
    callback(nil, children)
  end
end

return M
