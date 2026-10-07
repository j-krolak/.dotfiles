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
			multiline_threshold = 1, -- collapse each context to a single line (IDE-like)
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
