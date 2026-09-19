return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	-- lazy.nvim runs build before the plugin is on the rtp, so load it first
	-- https://github.com/iamcco/markdown-preview.nvim/issues/690
	build = function()
		require("lazy").load({ plugins = { "markdown-preview.nvim" } })
		vim.fn["mkdp#util#install"]()
	end,
	keys = {
		{
			"<leader>mp",
			"<cmd>MarkdownPreviewToggle<cr>",
			ft = "markdown",
			desc = "Markdown preview (browser)",
		},
	},
	init = function()
		vim.g.mkdp_auto_close = 0
		vim.g.mkdp_theme = "dark"
	end,
}
