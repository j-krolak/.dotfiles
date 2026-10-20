return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	event = "BufReadPost",
	opts = {
		provider_selector = function()
			return { "treesitter", "indent" }
		end,
	},
	keys = {
		{ "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
		{ "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
		{ "zp", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
	},
}
