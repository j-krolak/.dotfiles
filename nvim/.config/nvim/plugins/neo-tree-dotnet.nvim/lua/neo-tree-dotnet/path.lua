local M = {}
local uv = vim.uv or vim.loop

function M.normalize(path)
  return vim.fs.normalize((path:gsub("\\", "/")))
end

function M.absolute(path, base)
  path = M.normalize(path)
  if path:match("^/") or path:match("^%a:/") then
    return path
  end
  return M.normalize((base or vim.fn.getcwd()) .. "/" .. path)
end

function M.read(path)
  local file, err = io.open(path, "rb")
  if not file then
    error(err, 0)
  end
  local text = file:read("*a")
  file:close()
  return text:gsub("^\239\187\191", "")
end

function M.is_solution(path)
  return path:lower():match("%.slnx?$") ~= nil
end

function M.contains(directory, file)
  return directory ~= nil and file ~= nil and file:sub(1, #directory + 1) == directory .. "/"
end

-- Search the nearest ancestor first; never recursively scan a repository.
function M.discover(start)
  start = M.absolute(start)
  local stat = uv.fs_stat(start)
  local dir = stat and stat.type == "directory" and start or vim.fs.dirname(start)
  while dir do
    local result = {}
    local scan = uv.fs_scandir(dir)
    if scan then
      while true do
        local name, kind = uv.fs_scandir_next(scan)
        if not name then
          break
        end
        if kind ~= "directory" and M.is_solution(name) then
          result[#result + 1] = M.absolute(name, dir)
        end
      end
    end
    table.sort(result)
    if #result > 0 then
      return result
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return {}
end

return M
