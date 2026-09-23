return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = {
          normal = {
            a = { fg = "#ffffff", bg = "#007acc", gui = "bold" },
            b = { fg = "#cccccc", bg = "#252526" },
            c = { fg = "#9cdcfe", bg = "#1e1e1e" },
          },
          insert = { a = { fg = "#ffffff", bg = "#16825d", gui = "bold" } },
          visual = { a = { fg = "#ffffff", bg = "#68217a", gui = "bold" } },
          replace = { a = { fg = "#ffffff", bg = "#c72e0f", gui = "bold" } },
          command = { a = { fg = "#ffffff", bg = "#795e26", gui = "bold" } },
          inactive = {
            a = { fg = "#858585", bg = "#1e1e1e" },
            b = { fg = "#858585", bg = "#1e1e1e" },
            c = { fg = "#858585", bg = "#1e1e1e" },
          },
        },
      },
    },
  },
}
