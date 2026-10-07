return {
	{
		"Mofiqul/vscode.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local c = require("vscode.colors").get_colors()

			-- One diff palette shared by codediff (derives from DiffAdd/DiffDelete),
			-- :diffthis, gitsigns and pickers. Gutter colors are VS Code Dark+'s.
			local diff = {
				add = "#4b5632",
				delete = "#6f1313",
				change = "#373d29",
				text = "#697846",
				gutter_add = "#587c0c",
				gutter_change = "#0c7d9d",
				gutter_delete = "#94151b",
			}

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
					FloatBorder = { fg = c.vscSplitDark, bg = c.vscBack },
					FloatTitle = { fg = c.vscFront, bg = c.vscBack, bold = true },
					WinSeparator = { fg = c.vscSplitDark, bg = c.vscBack },
					DiffAdd = { bg = diff.add },
					DiffDelete = { bg = diff.delete },
					DiffChange = { bg = diff.change },
					DiffText = { bg = diff.text },
					Added = { fg = diff.gutter_add },
					Changed = { fg = diff.gutter_change },
					Removed = { fg = diff.gutter_delete },
					GitSignsAdd = { fg = diff.gutter_add },
					GitSignsChange = { fg = diff.gutter_change },
					GitSignsDelete = { fg = diff.gutter_delete },
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
