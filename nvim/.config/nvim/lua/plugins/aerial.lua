return {
	"stevearc/aerial.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("aerial").setup({
			backends = { "lsp", "treesitter", "markdown", "man" },
			layout = { min_width = 30 },
			attach_mode = "global",
			show_guides = true,
			filter_kind = false,
		})
		pcall(require("telescope").load_extension, "aerial")
	end,
	keys = {
		{ "<leader>o",  "<cmd>AerialToggle!<cr>",    desc = "Toggle Aerial outline" },
		{ "<leader>fo", "<cmd>Telescope aerial<cr>", desc = "Find symbol (Aerial)" },
		{ "{",          "<cmd>AerialPrev<cr>",       desc = "Aerial: previous symbol" },
		{ "}",          "<cmd>AerialNext<cr>",       desc = "Aerial: next symbol" },
	},
}
