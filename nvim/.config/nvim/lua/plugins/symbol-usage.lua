return {
	"Wansmer/symbol-usage.nvim",
	event = "LspAttach",
  enabled = false,
	config = function()
		local SymbolKind = vim.lsp.protocol.SymbolKind

		local function text_format(symbol)
			local fragments = {}

			if symbol.references then
				local word = symbol.references == 1 and "usage" or "usages"
				local num = symbol.references == 0 and "no" or symbol.references
				table.insert(fragments, ("%s %s"):format(num, word))
			end

			if symbol.implementation then
				local word = symbol.implementation == 1 and "implementation" or "implementations"
				table.insert(fragments, ("%s %s"):format(symbol.implementation, word))
			end

			return table.concat(fragments, ", ")
		end

		require("symbol-usage").setup({
			vt_position = "above",
			text_format = text_format,
			kinds = {
				SymbolKind.Class,
				SymbolKind.Interface,
				SymbolKind.Method,
				SymbolKind.Property,
				SymbolKind.Constructor,
				SymbolKind.Struct,
				SymbolKind.Enum,
			},
			references = { enabled = true, include_declaration = false },
			implementation = {
				enabled = true,
				-- Only meaningful for interfaces/methods (inheritors/overrides);
				-- on a plain class or property Roslyn just returns the symbol
				-- itself, producing a useless "1 implementation" everywhere.
				kinds = { SymbolKind.Interface, SymbolKind.Method },
			},
		})
	end,
}
