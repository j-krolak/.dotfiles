return
{
  {
    "LudoPinelli/comment-box.nvim",
    config = function()
      local opts = { noremap = true, silent = true }
      -- Titles
      vim.keymap.set({ "n", "v" }, "<Leader>cb", "<Cmd>CBccbox<CR>", opts)
      -- Simple line
      vim.keymap.set("n", "<Leader>cl", "<Cmd>CBline<CR>", opts)

      vim.keymap.set({ "n", "v" }, "<leader>ct", "<Cmd>CBllline<CR>", { desc = "Titled line" })
    end
  }
}
