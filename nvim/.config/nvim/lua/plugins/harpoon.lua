return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()
	end,
	keys = {
		-- Mark the file (add to list)
		{
			"<space>a",
			function()
				local harpoon = require("harpoon")
				harpoon:list():add()
			end,
			desc = "Harpoon File"
		},

		-- Open the menu to see your list
		{ "<space>j", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon Menu" },

		-- Navigate to files 1, 2, 3, 4 instantly
		{ "<C-h>",    function() require("harpoon"):list():select(1) end,                                desc = "Harpoon File 1" },
		{ "<C-j>",    function() require("harpoon"):list():select(2) end,                                desc = "Harpoon File 2" },
		{ "<C-k>",    function() require("harpoon"):list():select(3) end,                                desc = "Harpoon File 3" },
		{ "<C-l>",    function() require("harpoon"):list():select(4) end,                                desc = "Harpoon File 4" },
	},
}
