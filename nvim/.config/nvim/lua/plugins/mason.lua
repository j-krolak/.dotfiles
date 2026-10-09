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
			-- LemMinX gives completion/hover/validation for MSBuild XML (csproj, props, targets)
			-- and .slnx. Schemas are local: SDK-style projects have no xmlns, so the upstream MSBuild
			-- XSDs (which declare a targetNamespace) are vendored with the namespace stripped.
			-- .slnx has no official XSD, so a minimal hand-written one is used.
			-- https://github.com/redhat-developer/vscode-xml/blob/main/docs/Features/XMLFeatures.md
			vim.filetype.add({ extension = { slnx = "xml", props = "xml", targets = "xml" } })
			vim.lsp.config("lemminx", {
				filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
				settings = {
					xml = {
						fileAssociations = {
							{
								pattern = "**/*.{csproj,vbproj,fsproj,props,targets}",
								systemId = "file://" .. vim.fn.stdpath("config") .. "/schemas/msbuild/Microsoft.Build.xsd",
							},
							{
								pattern = "**/*.slnx",
								systemId = "file://" .. vim.fn.stdpath("config") .. "/schemas/slnx.xsd",
							},
						},
					},
				},
			})

			-- mason-lspconfig only installs LSP servers; formatters go through the registry.
			local registry = require("mason-registry")
			registry.refresh(function()
				for _, name in ipairs({ "clang-format" }) do
					local pkg = registry.get_package(name)
					if not pkg:is_installed() then
						pkg:install()
					end
				end
			end)

			require("mason-lspconfig").setup({
				ensure_installed = { "clangd", "lemminx", "lua_ls" },
				-- easy-dotnet.nvim ships its own Roslyn client ("easy_dotnet"); letting
				-- mason-lspconfig also auto-enable the generic "roslyn_ls" server attaches
				-- a second LSP client to C# buffers, doubling codelens (e.g. references count).
				automatic_enable = { exclude = { "roslyn_ls" } },
			})
		end
	},
}
