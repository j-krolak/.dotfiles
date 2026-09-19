return {
	"saghen/blink.cmp",
	dependencies = { 'saghen/blink.lib' },
	opts = {
		fuzzy = { implementation = "lua" },
		keymap = {
			preset = 'none',
			['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
			['<C-e>'] = { 'hide', 'fallback' },
			['<CR>'] = { 'accept', 'fallback' },
			['<C-y>'] = { 'select_and_accept', 'fallback' },
			['<C-n>'] = {
				function(cmp)
					if not cmp.is_menu_visible() then return cmp.show() end
					return cmp.select_next()
				end,
			},
			['<C-p>'] = {
				function(cmp)
					if not cmp.is_menu_visible() then return cmp.show() end
					return cmp.select_prev()
				end,
			},

			-- Keep completion/snippet navigation separate from Copilot suggestions.
			['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
			['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },

			['<C-d>'] = { 'scroll_documentation_up', 'fallback' },
			['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
		},
		completion = {
			menu = {
				winblend = vim.o.pumblend,
			},
		},
		signature = {
			window = {
				winblend = vim.o.pumblend,
			},
		},
	},
}
