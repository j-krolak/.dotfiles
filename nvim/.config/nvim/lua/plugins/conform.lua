return {
  'stevearc/conform.nvim',
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ bufnr = 0, lsp_format = "fallback" })
      end,
      mode = "n",
      desc = "Format buffer",
    },
  },
  config = function()
    local conform = require("conform")
    conform.setup({
      formatters_by_ft = {
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        csharp = { "csharpier" },
        xml = { "lemminx" },
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 1000,
      },
    })
  end,
}
