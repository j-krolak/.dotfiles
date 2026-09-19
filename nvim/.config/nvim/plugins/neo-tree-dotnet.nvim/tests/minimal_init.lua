vim.opt.swapfile = false
vim.opt.shadafile = "NONE"
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local deps = vim.env.NEOTREE_TEST_DEPS or (vim.fn.stdpath("data") .. "/lazy")
-- Keep test logs/runtime files out of both the repository and the user's config.
-- Resolve installed dependencies before redirecting stdpath() for this process.
local test_runtime = vim.fn.tempname()
vim.fn.mkdir(test_runtime .. "/data/nvim", "p")
vim.fn.mkdir(test_runtime .. "/state/nvim", "p")
vim.env.XDG_DATA_HOME = test_runtime .. "/data"
vim.env.XDG_STATE_HOME = test_runtime .. "/state"
vim.env.XDG_RUNTIME_DIR = test_runtime
vim.env.NVIM_LOG_FILE = test_runtime .. "/nvim.log"

for _, name in ipairs({ "plenary.nvim", "nui.nvim", "neo-tree.nvim" }) do
  local dir = deps .. "/" .. name
  assert(vim.fn.isdirectory(dir) == 1, "Missing test dependency: " .. dir)
  vim.opt.runtimepath:append(dir)
end
vim.opt.lines = 40
vim.opt.columns = 120
