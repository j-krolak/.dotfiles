local theme = os.getenv("NEOVIM_THEME") or "tokyonight"

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    enabled = theme == "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        integrations = {
          blink_cmp = true,
          bufferline = true,
          gitsigns = true,
          harpoon = true,
          mason = true,
          neotree = true,
          noice = true,
          snacks = true,
          treesitter = true,
          trouble = true,
          which_key = true,
        },
      })

      vim.cmd.colorscheme("catppuccin")

      -- Make LSP codelens (e.g. "N references") read as a subtle annotation.
      -- (Setting `link` together with other attrs drops the attrs at render time,
      -- so copy Comment's resolved colors instead of linking to it.)
      local function style_codelens()
        local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
        vim.api.nvim_set_hl(0, "LspCodeLens", vim.tbl_extend("force", comment, { italic = true }))
        vim.api.nvim_set_hl(0, "LspCodeLensSeparator", vim.tbl_extend("force", comment, { italic = true }))
      end
      style_codelens()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = style_codelens })
    end,
  }, {
  "scottmckendry/cyberdream.nvim",
  enabled = theme == "cyberdream",
  lazy = false,
  priority = 1000,
  opts = {
    transparent = true,
    borderless_pickers = false,
    saturation = 0.95,
    cache = true,
  },
  config = function(_, opts)
    require("cyberdream").setup(opts)
    vim.cmd.colorscheme("cyberdream")

    local function style()
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#3c4048", bg = "none" })
      vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#232429" })
      vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = "#232429" })
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { bg = "#232429", underline = true })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffffff" })
      local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
      vim.api.nvim_set_hl(0, "LspCodeLens", vim.tbl_extend("force", comment, { italic = true }))
      vim.api.nvim_set_hl(0, "LspCodeLensSeparator", vim.tbl_extend("force", comment, { italic = true }))
    end
    style()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = style })
  end,
}, {
  "sainnhe/everforest",
  enabled = theme == "everforest",
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.everforest_background = "medium"
    vim.g.everforest_transparent_background = 1
    vim.g.everforest_enable_italic = 1
    vim.g.everforest_better_performance = 1
    vim.o.background = "dark"
    vim.cmd.colorscheme("everforest")
  end,
}, {
  "rebelot/kanagawa.nvim",
  enabled = theme == "kanagawa",
  lazy = false,
  priority = 1000,
  opts = { transparent = true },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    vim.cmd.colorscheme("kanagawa")
  end,
},
  {
    "rose-pine/neovim",
    name = "rose-pine",
    enabled = theme == "rose-pine",
    lazy = false,
    priority = 1000,
    opts = { styles = { transparency = true } },
    config = function(_, opts)
      require("rose-pine").setup(opts)
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  {
    "Mofiqul/vscode.nvim",
    enabled = theme == "vscode",
    lazy = false,
    priority = 1000,
    config = function()
      local function style()
        vim.cmd.colorscheme("vscode")
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ffffff" })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a3350" })
      end

      local function set_ws_colors()
        vim.api.nvim_set_hl(0, "Whitespace", { fg = "#7a8394" })
        vim.api.nvim_set_hl(0, "NonText", { fg = "#7a8394" })
        vim.api.nvim_set_hl(0, "VirtColumn", { fg = "#4a505c" })
      end

      require("vscode").setup({
        italic_comments = true,
        -- transparent = true
      })
      style()

      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_ws_colors })
    end,
  },
  {
    "folke/tokyonight.nvim",
    enabled = theme == "tokyonight",
    lazy = false,
    priority = 1000,
    opts = { transparent = true, styles = { sidebars = "transparent", floats = "transparent" } },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    enabled = theme == "github-nvim-theme",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("github_dark_dimmed")
      local function set_ws_colors()
        vim.api.nvim_set_hl(0, "Whitespace", { fg = "#5c6370" })
        vim.api.nvim_set_hl(0, "NonText", { fg = "#5c6370" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_ws_colors })
      set_ws_colors()
    end,
  }
}
