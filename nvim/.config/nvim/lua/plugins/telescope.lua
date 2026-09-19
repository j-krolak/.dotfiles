return {
	{
		'nvim-telescope/telescope.nvim',
		version = '*',
		dependencies = {
			'nvim-lua/plenary.nvim',
			-- optional but recommended
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
		},
		config = function()
			require('telescope').setup {
				defaults = {
					vimgrep_arguments = {
						"rg", "--color=never", "--no-heading", "--with-filename",
						"--line-number", "--column", "--smart-case", "--hidden",
						"--glob", "!**/.git/*",
					},
				},
				pickers = {
					find_files = {
						theme = "ivy",
						hidden = true,
						find_command = {
							"rg", "--files", "--hidden", "--glob", "!**/.git/*",
						},
					},
				},
			}

			local builtin = require('telescope.builtin')
			vim.keymap.set("n", "<space>fh", builtin.help_tags)
			vim.keymap.set("n", "<space>ff", builtin.find_files)
			vim.keymap.set("n", "<space>fg", builtin.live_grep)
			vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Find references" })
			vim.keymap.set("n", "<leader>fi", builtin.lsp_implementations, { desc = "Find implementations" })
			vim.keymap.set("n", "<space>fa", function()
				builtin.find_files { hidden = true, no_ignore = true }
			end, { desc = "Find files (all: hidden + ignored)" })
			vim.keymap.set("n", "<space>en", function()
				require('telescope.builtin').find_files {
					cwd = vim.fn.stdpath("config")
				}
			end)
			vim.keymap.set("n", "<space>ep", function()
				require('telescope.builtin').find_files {
					cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
				}
			end)
		end
	}
}
