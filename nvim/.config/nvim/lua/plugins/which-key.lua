return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- normal mode only; no popup in visual/select/operator-pending
		triggers = { { "<auto>", mode = "n" } },
		spec = {
			{ "<leader>b", group = "buffer" },
			{ "<leader>c", group = "code" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>G", group = "github (octo)" },
			{ "<leader>m", group = "markdown" },
			{ "<leader>n", group = "neogit" },
			{ "<leader>s", group = "session" },
			{ "<leader>x", group = "trouble" },
		},
	},
	keys = {
		{ "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
	},
}
