vim.keymap.set("n", "<C-w>l", "<cmd>nohl<CR>", { desc = "Remove highlight" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
