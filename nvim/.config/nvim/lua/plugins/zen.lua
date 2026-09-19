return {
	"folke/zen-mode.nvim",
	opts = {
		window = {
			backdrop = 1,
			width = 160,
			height = 0.9,
		},
	},
	keys = {
		{ "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" },
	},
}
