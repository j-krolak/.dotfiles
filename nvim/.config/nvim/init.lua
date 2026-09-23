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

-- Improve default search behavior
vim.o.incsearch = true

vim.o.cursorline = true

vim.opt.title = true

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.lsp.buf.document_highlight()
  end,
})

vim.api.nvim_create_autocmd("CursorHoldI", {
  callback = function()
    vim.lsp.buf.document_highlight()
  end,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    vim.lsp.buf.clear_references()
  end,
})







