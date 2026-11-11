return {
	"jake-stewart/multicursor.nvim",
	event = "BufReadPost",
	config = function()
		local mc = require("multicursor-nvim")
		mc.setup()

		local map = vim.keymap.set

		map({ "n", "v" }, "<C-A-k>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
		map({ "n", "v" }, "<C-A-j>", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })

		map("n", "<C-n>", "viw", { desc = "Select word" })
		map("v", "<C-n>", function() mc.addCursor("*") end, { desc = "Add cursor at next match" })
		map({ "n", "v" }, "<C-A-n>", function() mc.skipCursor("*") end, { desc = "Skip next match" })

		map("v", "I", mc.insertVisual)

		map("n", "<esc>", function()
			if not mc.cursorsEnabled() then
				mc.enableCursors()
			elseif mc.hasCursors() then
				mc.clearCursors()
			else
				vim.cmd("nohlsearch")
			end
		end)
	end,
}
