return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- normal mode only; no popup in visual/select/operator-pending
		triggers = { { "<auto>", mode = "n" } },
		spec = {
			{ "<leader>c", group = "code" },
			{ "<leader>e", group = "explorer" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>m", group = "markdown" },
			{ "<leader>n", group = "neogit" },
			{ "<leader>o", group = "outline / octo" },
			{ "<leader>s", group = "session" },
		},
	},
	keys = {
		{ "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
	},
}
