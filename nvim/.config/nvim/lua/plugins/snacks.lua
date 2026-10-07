local function pick(source, opts)
	return function()
		Snacks.picker[source](opts)
	end
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		dashboard = { enabled = true },
		indent = { enabled = true },
		notifier = { enabled = true },
		picker = { enabled = true },
		words = { enabled = true },
		zen = { toggles = { dim = false } },
		styles = {
			zen = { width = 160 },
			float_term = {
				position = "float",
				border = "rounded",
				-- the dimmed backdrop renders as an offset grey block under tmux
				backdrop = false,
				width = 0.85,
				height = 0.8,
				title = " Terminal ",
				title_pos = "center",
			},
		},
	},
	keys = {
		{ "<leader>ff", pick("files", { hidden = true, layout = "ivy" }), desc = "Find files" },
		{ "<leader>fa", pick("files", { hidden = true, ignored = true }), desc = "Find files (all: hidden + ignored)" },
		{ "<leader>fg", pick("grep", { hidden = true }), desc = "Live grep" },
		{ "<leader>fh", pick("help"), desc = "Help tags" },
		{ "<leader>fr", pick("lsp_references"), desc = "Find references" },
		{ "<leader>fi", pick("lsp_implementations"), desc = "Find implementations" },
		{ "<leader>fo", pick("lsp_symbols"), desc = "Find symbol" },
		{ "<leader>fd", pick("diagnostics_buffer"), desc = "Find diagnostics (buffer)" },
		{ "<leader>fD", pick("diagnostics"), desc = "Find diagnostics (workspace)" },
		{ "<leader>fn", pick("notifications"), desc = "Notification history" },
		{ "<leader>en", pick("files", { cwd = vim.fn.stdpath("config") }), desc = "Edit Neovim config" },
		{ "<leader>ep", pick("files", { cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy") }), desc = "Edit plugins" },
		{ "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode" },
		{ "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference" },
		{ "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference" },
		{
			"<C-\\>",
			function() Snacks.terminal.toggle(nil, { win = { style = "float_term" } }) end,
			mode = { "n", "t", "i" },
			desc = "Toggle terminal",
		},
	},
}
