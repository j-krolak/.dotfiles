vim.keymap.set("n", "<Esc>", "<cmd>nohl<CR>", { desc = "Remove highlight" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

local function jump(count, severity)
  return function()
    vim.diagnostic.jump({ count = count, severity = severity, float = true })
  end
end
vim.keymap.set("n", "]d", jump(1), { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", jump(-1), { desc = "Prev diagnostic" })
vim.keymap.set("n", "]e", jump(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })
vim.keymap.set("n", "[e", jump(-1, vim.diagnostic.severity.ERROR), { desc = "Prev error" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
