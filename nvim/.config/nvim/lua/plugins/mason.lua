return {
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = {}
			},
			"neovim/nvim-lspconfig",
		},
		config = function()
			-- Vue 3 "hybrid mode": vue_ls handles templates but delegates TS type info
			-- to ts_ls, which must attach to .vue files AND load @vue/typescript-plugin.
			-- https://github.com/vuejs/language-tools/wiki/Neovim
			local vue_ls_path = vim.fn.stdpath("data")
				.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
			vim.lsp.config("ts_ls", {
				init_options = {
					plugins = {
						{
							name = "@vue/typescript-plugin",
							location = vue_ls_path,
							languages = { "vue" },
							configNamespace = "typescript",
						},
					},
				},
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
			})

			require("mason-lspconfig").setup({
				ensure_installed = { "ts_ls", "vue_ls", "clangd", "pyright", "eslint", "lua_ls", "html", "cssls" },
				-- easy-dotnet.nvim ships its own Roslyn client ("easy_dotnet"); letting
				-- mason-lspconfig also auto-enable the generic "roslyn_ls" server attaches
				-- a second LSP client to C# buffers, doubling codelens (e.g. references count).
				automatic_enable = { exclude = { "roslyn_ls" } },
			})
		end
	},
}
