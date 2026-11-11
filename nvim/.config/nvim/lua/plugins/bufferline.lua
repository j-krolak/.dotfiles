return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local fill, active, inactive = "#16161e", "#e0af68", "#1d4a5c"
      local active_fg, inactive_fg = "#1a1b26", "#c0caf5"
      local function tab(bg, fg, bold)
        return { bg = bg, fg = fg, bold = bold, italic = false }
      end
      local custom = {
        fill = { bg = fill },
        background = tab(inactive, inactive_fg),
        tab = tab(inactive, inactive_fg),
        tab_selected = tab(active, active_fg, true),
        tab_close = tab(inactive, inactive_fg),
        buffer_visible = tab(inactive, inactive_fg),
        buffer_selected = tab(active, active_fg, true),
        close_button = tab(inactive, inactive_fg),
        close_button_visible = tab(inactive, inactive_fg),
        close_button_selected = tab(active, active_fg),
        modified = tab(inactive, active),
        modified_visible = tab(inactive, active),
        modified_selected = tab(active, active_fg),
        numbers = tab(inactive, inactive_fg),
        numbers_visible = tab(inactive, inactive_fg),
        numbers_selected = tab(active, active_fg, true),
        duplicate = tab(inactive, inactive_fg),
        duplicate_visible = tab(inactive, inactive_fg),
        duplicate_selected = tab(active, active_fg),
        separator = { fg = fill, bg = inactive },
        separator_visible = { fg = fill, bg = inactive },
        separator_selected = { fg = fill, bg = active },
        indicator_selected = { fg = active, bg = active },
        indicator_visible = { fg = inactive, bg = inactive },
      }
      return {
        options = {
          mode = "tabs",
          always_show_bufferline = false,
          separator_style = "slant",
          indicator = { style = "none" },
          tab_size = 18,
          modified_icon = "●",
          show_close_icon = false,
          show_buffer_close_icons = false,
          offsets = {
            { filetype = "neo-tree", text = "Explorer", highlight = "Directory", separator = true },
          },
        },
        highlights = custom,
      }
    end,
  },
}
