require("config.lazy")
require("config.keymap")
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.wrap = false
vim.opt.fillchars:append({ diff = " " })

vim.o.cursorline = true

vim.opt.title = true

-- Folding: treesitter by default, LSP when the server supports it. Everything starts open.
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99
vim.o.foldtext = ""

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local win = vim.fn.bufwinid(ev.buf)
    if win ~= -1 and client and client:supports_method("textDocument/foldingRange") then
      vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
  end,
})
