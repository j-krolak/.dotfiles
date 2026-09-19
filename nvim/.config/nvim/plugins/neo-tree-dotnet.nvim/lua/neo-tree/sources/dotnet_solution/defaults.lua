local mappings = {
  ["<cr>"] = "open",
  ["<2-LeftMouse>"] = "open",
  -- Space is also the user's leader: wait for the rest of a key sequence.
  ["<space>"] = { "toggle_node", nowait = false },
  o = "open",
  s = "open_vsplit",
  S = "open_split",
  t = "open_tabnew",
  R = "refresh",
  gs = "choose_solution",
  gf = "switch_view",
  O = "open_definition",
}

-- A virtual solution folder is not a filesystem directory. Disable inherited
-- filesystem actions and commands that this source does not implement.
for _, key in ipairs({
  "a", "A", "d", "r", "y", "x", "p", "c", "m", "/", "f", "H", ".", "<bs>",
  "e", "<C-s>", "U", "<C-S-i>", "<C-;>", "<C-f>", "<C-b>", "u", "<C-r>",
  "w", "T", "P", "l", "<esc>", "<Tab>",
}) do
  mappings[key] = "none"
end

return {
  project_files = "filesystem", -- or "msbuild" for evaluated items and references
  excluded_dirs = { "bin", "obj", ".git", ".vs", "node_modules" },
  dotnet_command = "dotnet",
  msbuild_timeout = 30000,
  msbuild_properties = { Configuration = "Debug" },
  bind_to_cwd = false,
  follow_current_file = { enabled = true },
  window = { mappings = mappings },
  renderers = {
    directory = { { "indent" }, { "icon" }, { "name" } },
    file = { { "indent" }, { "icon" }, { "name" }, { "modified" } },
    message = { { "indent" }, { "name" } },
  },
}
