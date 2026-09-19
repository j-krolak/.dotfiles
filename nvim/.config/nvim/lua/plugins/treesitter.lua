return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",

		lazy = false,
		config = function()
			require('nvim-treesitter').setup()

			local want = { "c", "c_sharp", "bash", "regex", "javascript", "typescript", "lua", "vim", "vimdoc", "query",
				"markdown", "markdown_inline" }
			local have = require('nvim-treesitter.config').get_installed()
			local todo = vim.iter(want):filter(function(p)
				return not vim.tbl_contains(have, p)
			end):totable()
			require('nvim-treesitter').install(todo)

			vim.api.nvim_create_autocmd('FileType', {
				callback = function()
					pcall(vim.treesitter.start)
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			enable = true,         -- Enable this plugin (Can be enabled/disabled later via commands)
			multiwindow = false,   -- Enable multiwindow support.
			max_lines = 0,         -- How many lines the window should span. Values <= 0 mean no limit.
			min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
			line_numbers = true,
			multiline_threshold = 1, -- Collapse each context to a single line (IDE-like)
			trim_scope = 'outer',  -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
			mode = 'cursor',       -- Line used to calculate context. Choices: 'cursor', 'topline'
			-- Separator between context and content. Should be a single character string, like '-'.
			-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
			separator = nil,
			zindex = 20,  -- The Z-index of the context window
			on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
		},
		config = function(_, opts)
			require("treesitter-context").setup(opts)

			local function set_hl()
				vim.api.nvim_set_hl(0, "TreesitterContext", { link = "Normal" })
				vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { link = "LineNr" })
				vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#3c3c3c" })
			end
			set_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
		end,
	}
}
