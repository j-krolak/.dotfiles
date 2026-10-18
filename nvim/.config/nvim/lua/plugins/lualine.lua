return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- theme defaults to "auto", which picks up catppuccin-mocha from the colorscheme
      sections = {
        lualine_c = {
          { "filename" },
          {
            "diagnostics",
            sources = { "nvim_workspace_diagnostic" },
            sections = { "error", "warn" },
          },
        },
      },
    },
  },
}
