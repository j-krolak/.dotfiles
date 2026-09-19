return {
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local c = require("vscode.colors").get_colors()

			require("vscode").setup({
				style = "dark",
				transparent = false,
				italic_comments = true,
				underline_links = true,
				disable_nvimtree_bg = true,
				terminal_colors = true,
				group_overrides = {
					-- VSCode paints the gutter/sign column in the editor background.
					SignColumn = { bg = c.vscBack },
					CursorLineNr = { fg = c.vscFront },
					-- Match the VSCode peek/selection highlight for LSP references.
					LspReferenceText = { bg = c.vscSelection },
					LspReferenceRead = { bg = c.vscSelection },
					LspReferenceWrite = { bg = c.vscSelection },
					NormalFloat = { bg = c.vscBack },
					FloatBorder = { fg = c.vscPopupHighlightBlue, bg = c.vscBack },
					WinSeparator = { fg = c.vscSplitDark, bg = c.vscBack },
				},
			})

			require("vscode").load()

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
