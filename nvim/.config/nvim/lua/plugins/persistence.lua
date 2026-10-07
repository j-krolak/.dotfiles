return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = {},
	-- <leader>s* instead of the README's <leader>q*, which is the diagnostics loclist
	keys = {
		{ "<leader>ss", function() require("persistence").load() end, desc = "Restore session (cwd)" },
		{ "<leader>sS", function() require("persistence").select() end, desc = "Select session" },
		{ "<leader>sl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
		{ "<leader>sd", function() require("persistence").stop() end, desc = "Don't save current session" },
	},
}
