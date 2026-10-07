return {
	"GustavEikaas/easy-dotnet.nvim",
	ft = { "cs", "fsharp" },
	dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap", "folke/snacks.nvim" },
	config = function()
		local dotnet = require("easy-dotnet")
		dotnet.setup({
			picker = "snacks",
			auto_bootstrap_namespace = { type = "file_scoped" },
			lsp = { auto_refresh_codelens = false },
		})

		vim.api.nvim_create_user_command("Secrets", function()
			dotnet.secrets()
		end, {})

		vim.keymap.set("n", "<C-p>", function()
			vim.cmd("Dotnet run profile default")
		end, { desc = "Dotnet run (default profile)" })
	end,
}
