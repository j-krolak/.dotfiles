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

vim.o.foldcolumn = "1"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.opt.fillchars:append({ fold = " ", foldopen = "▾", foldclose = "▸", foldsep = " " })
