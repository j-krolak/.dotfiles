return {
	"stevearc/oil.nvim",
	-- not lazy: default_file_explorer must hijack directory buffers at startup
	lazy = false,
	keys = {
		{ "-", "<cmd>Oil<CR>", silent = true, desc = "Open parent directory (Oil)" },
		{
			"<leader>-",
			function()
				if vim.bo.filetype == "oil" then
					require("oil").close()
				else
					require("oil").open()
				end
			end,
			desc = "Toggle Oil",
		},
	},
	opts = {
		keymaps = {
			["q"] = { "actions.close", mode = "n" },
			["cc"] = {
				desc = "Copy filepath to system clipboard",
				callback = function()
					require("oil.actions").copy_entry_path.callback()
					vim.fn.setreg("+", vim.fn.getreg(vim.v.register))
					vim.notify("Copied full path", vim.log.levels.INFO, { title = "Oil" })
				end,
			},
		},
		default_file_explorer = true,
		delete_to_trash = true,
		view_options = {
			show_hidden = true,
			case_insensitive = true,
		},
		lsp_file_methods = {
			autosave_changes = true,
		},
	},
}
