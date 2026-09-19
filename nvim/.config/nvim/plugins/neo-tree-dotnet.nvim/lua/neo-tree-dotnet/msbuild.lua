local M = {}

M.item_types = {
  "Compile", "Content", "None", "EmbeddedResource", "AdditionalFiles",
  "Page", "ApplicationDefinition", "Resource", "RazorComponent", "RazorGenerate",
}

local function arguments(file, options, framework)
  local args = {
    options.dotnet_command,
    "msbuild",
    file,
    "-nologo",
    "-getProperty:TargetFramework,TargetFrameworks",
    "-getItem:" .. table.concat(M.item_types, ",") .. ",ProjectReference,PackageReference,PackageVersion",
  }
  local properties = vim.tbl_keys(options.msbuild_properties)
  table.sort(properties)
  for _, key in ipairs(properties) do
    args[#args + 1] = "-property:" .. key .. "=" .. tostring(options.msbuild_properties[key])
  end
  if framework then
    args[#args + 1] = "-property:TargetFramework=" .. framework
  end
  return args
end

local function decode(result)
  if result.code ~= 0 then
    return nil, vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
  end
  local ok, data = pcall(vim.json.decode, result.stdout)
  if not ok or type(data) ~= "table" or type(data.Items) ~= "table" then
    return nil, "MSBuild did not return item JSON; .NET SDK 8+ is required"
  end
  return data
end

local function first_framework(data, options)
  local properties = data.Properties or {}
  if options.msbuild_properties.TargetFramework then
    return nil
  end
  if properties.TargetFramework and properties.TargetFramework ~= "" then
    return nil
  end
  return (properties.TargetFrameworks or ""):match("^[^;]+")
end

-- Evaluation only: no build or restore target. Deliver decoded data on Neovim's
-- main loop; rendering and translating items into nodes belong to the caller.
function M.read(file, options, callback)
  local function run(framework)
    local function complete(result)
      local data, err = decode(result)
      if not data then
        callback(nil, err)
        return
      end
      local selected = not framework and first_framework(data, options)
      if selected then
        run(selected)
      else
        callback(data)
      end
    end

    local ok, err = pcall(vim.system, arguments(file, options, framework), {
      cwd = vim.fs.dirname(file),
      text = true,
      timeout = options.msbuild_timeout,
      env = {
        DOTNET_NOLOGO = "1",
        DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1",
        DOTNET_CLI_TELEMETRY_OPTOUT = "1",
      },
    }, vim.schedule_wrap(complete))
    if not ok then
      callback(nil, tostring(err))
    end
  end
  run(nil)
end

return M
