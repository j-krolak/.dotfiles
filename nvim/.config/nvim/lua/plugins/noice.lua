return { {
  "folke/noice.nvim",
  dependencies = {
    "rcarriga/nvim-notify",
  },
  opts = {
    presets = {
      lsp_doc_border = true
    },
    views = {
      mini = {
        timeout = 60000,
      },
    },
    routes = {
      {
        filter = {
          event = "notify",
          find = "No information available"
        },
        opts = { skip = true }
      },
      {
        filter = { event = "notify" },
        view = "mini"
      }
    }
  }
} }
