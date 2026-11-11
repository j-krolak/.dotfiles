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
vim.opt.splitright = true

vim.wo.signcolumn = "yes"
vim.opt.list = true
vim.opt.listchars = vim.opt.listchars + "space:·"

vim.lsp.inlay_hint.enable(true)

vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.opt.fillchars:append({ fold = "·", foldopen = "▾", foldclose = "▸", foldsep = " " })
