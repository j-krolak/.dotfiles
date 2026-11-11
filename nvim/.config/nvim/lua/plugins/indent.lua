return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = "BufReadPost",
	init = function()
		local function set_hl()
			vim.api.nvim_set_hl(0, "IndentBlanklineChar", { fg = "#7b8496" })
		end
		set_hl()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
	end,
	opts = {
		indent = { highlight = { "WhiteSpace" }, char = "┊" },
		scope = {
			show_start = false,
			show_end = false,
			char = "│",
			highlight = { "IndentBlanklineChar" },
		},
	},
}
