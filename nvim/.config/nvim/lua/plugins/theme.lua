return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				transparent_background = false,
				integrations = {
					blink_cmp = true,
					gitsigns = true,
					harpoon = true,
					mason = true,
					neotree = true,
					noice = true,
					snacks = true,
					treesitter = true,
					trouble = true,
					which_key = true,
				},
			})

			vim.cmd.colorscheme("catppuccin")

			-- Make LSP codelens (e.g. "N references") read as a subtle annotation.
			-- (Setting `link` together with other attrs drops the attrs at render time,
			-- so copy Comment's resolved colors instead of linking to it.)
			local function style_codelens()
				local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
				vim.api.nvim_set_hl(0, "LspCodeLens", vim.tbl_extend("force", comment, { italic = true }))
				vim.api.nvim_set_hl(0, "LspCodeLensSeparator", vim.tbl_extend("force", comment, { italic = true }))
			end
			style_codelens()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = style_codelens })
		end,
	},
}
