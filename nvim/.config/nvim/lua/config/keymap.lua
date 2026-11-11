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

vim.keymap.set("n", "<leader>uh", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

local function copy_path(absolute)
  return function()
    local path = vim.fn.expand(absolute and "%:p" or "%:.")
    local text = ("%s#L%d"):format(path, vim.fn.line("."))
    vim.fn.setreg("+", text)
    vim.notify("Copied " .. text)
  end
end
vim.keymap.set("n", "<leader>yf", copy_path(false), { desc = "Copy relative path#L" })
vim.keymap.set("n", "<leader>yp", copy_path(true), { desc = "Copy absolute path#L" })

vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })

vim.keymap.set("n", "te", "<cmd>tabedit<CR>", { desc = "Open a new tab" })
for _, k in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("n", "s" .. k, "<C-w>" .. k, { desc = "Move between windows" })
end

vim.keymap.set("n", "tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
