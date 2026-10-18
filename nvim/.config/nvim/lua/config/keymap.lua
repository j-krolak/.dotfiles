vim.keymap.set("n", "<Esc>", "<cmd>nohl<CR>", { desc = "Remove highlight" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
  -- Applies to every jump, including the built-in ]d / [d.
  jump = {
    on_jump = function(diagnostic)
      if diagnostic then vim.diagnostic.open_float() end
    end,
  },
})

local function jump(count)
  return function()
    vim.diagnostic.jump({ count = count, severity = vim.diagnostic.severity.ERROR })
  end
end
vim.keymap.set("n", "]e", jump(1), { desc = "Next error" })
vim.keymap.set("n", "[e", jump(-1), { desc = "Prev error" })
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
