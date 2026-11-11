return {
	"GustavEikaas/easy-dotnet.nvim",
	ft = { "cs", "fsharp" },
	dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap", "folke/snacks.nvim" },
	config = function()
		local dotnet = require("easy-dotnet")
		dotnet.setup({
			picker = "snacks",
			auto_bootstrap_namespace = { type = "file_scoped" },
			lsp = {
				auto_refresh_codelens = false,
				config = {
					settings = {
						["csharp|inlay_hints"] = {
							csharp_enable_inlay_hints_for_parameters = true,
							dotnet_enable_inlay_hints_for_parameters = true,
							dotnet_enable_inlay_hints_for_literal_parameters = true,
							dotnet_enable_inlay_hints_for_object_creation_parameters = true,
							dotnet_enable_inlay_hints_for_other_parameters = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
							dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
							csharp_enable_inlay_hints_for_implicit_object_creation = true,
							csharp_enable_inlay_hints_for_implicit_variable_types = true,
						},
					},
				},
			},
		})

		vim.api.nvim_create_user_command("Secrets", function()
			dotnet.secrets()
		end, {})

		vim.keymap.set("n", "<C-p>", function()
			vim.cmd("Dotnet run profile default")
		end, { desc = "Dotnet run (default profile)" })
	end,
}
