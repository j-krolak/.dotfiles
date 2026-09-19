if vim.g.loaded_neo_tree_dotnet then
  return
end
vim.g.loaded_neo_tree_dotnet = true

vim.api.nvim_create_user_command("NeotreeDotnetPanelToggle", function()
  require("neo-tree-dotnet").toggle_panel()
end, { desc = "Hide/show Neo-tree, remembering the view in this tab" })

vim.api.nvim_create_user_command("NeotreeDotnetToggle", function()
  require("neo-tree-dotnet").toggle()
end, { desc = "Switch Neo-tree between files and .NET solution" })

vim.api.nvim_create_user_command("NeotreeDotnet", function(args)
  require("neo-tree-dotnet").open(args.args)
end, { nargs = "?", complete = "file", desc = "Open .NET solution in Neo-tree" })
