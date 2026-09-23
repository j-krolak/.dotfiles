return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	---@module "ibl"
	---@type ibl.config
	opts = {
		exclude = {
			filetypes = {
				"dashboard",
				"alpha",
				"starter",
				"neo-tree",
				"trouble",
				"lazy",
				"mason",
				"notify",
				"toggleterm",
			},
		},
	},
}
