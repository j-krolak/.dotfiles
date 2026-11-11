return {
  "stevearc/oil.nvim",
  -- not lazy: default_file_explorer must hijack directory buffers at startup
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<CR>", silent = true, desc = "Open parent directory (Oil)" },
    {
      "<leader>fe",
      function()
        require("oil").toggle_float()
      end,
      desc = "Toggle file explorer",
    },
  },
  opts = {
    keymaps = {
      ["q"] = { "actions.close", mode = "n" },
      ["cc"] = {
        desc = "Copy filepath to system clipboard",
        callback = function()
          require("oil.actions").copy_entry_path.callback()
          vim.fn.setreg("+", vim.fn.getreg(vim.v.register))
          vim.notify("Copied full path", vim.log.levels.INFO, { title = "Oil" })
        end,
      },
    },
    float = {
      border = "rounded",
    },
    columns = { "icon", "permissions" },
    default_file_explorer = true,
    delete_to_trash = true,
    view_options = {
      show_hidden = true,
      case_insensitive = true,
    },
    lsp_file_methods = {
      autosave_changes = true,
    },
  },
}
