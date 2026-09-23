return {
	{
		'nvim-telescope/telescope.nvim',
		version = '*',
		cmd = "Telescope",
		dependencies = {
			'nvim-lua/plenary.nvim',
			-- optional but recommended
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
		},
		-- Loaded on first keypress. The keymaps must live here (not in config),
		-- otherwise they don't exist until telescope is already loaded.
		keys = {
			{ "<space>fh", function() require('telescope.builtin').help_tags() end, desc = "Help tags" },
			{ "<space>ff", function() require('telescope.builtin').find_files() end, desc = "Find files" },
			{ "<space>fg", function() require('telescope.builtin').live_grep() end, desc = "Live grep" },
			{ "<leader>fr", function() require('telescope.builtin').lsp_references() end, desc = "Find references" },
			{ "<leader>fi", function() require('telescope.builtin').lsp_implementations() end, desc = "Find implementations" },
			{
				"<space>fa",
				function() require('telescope.builtin').find_files { hidden = true, no_ignore = true } end,
				desc = "Find files (all: hidden + ignored)",
			},
			{
				"<space>en",
				function() require('telescope.builtin').find_files { cwd = vim.fn.stdpath("config") } end,
				desc = "Edit Neovim config",
			},
			{
				"<space>ep",
				function()
					require('telescope.builtin').find_files { cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy") }
				end,
				desc = "Edit plugins",
			},
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
		end
	}
}
