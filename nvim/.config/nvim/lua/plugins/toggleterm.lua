return {
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        opts = {
            size = 20,
            open_mapping = [[<c-\>]],
            direction = 'float',
            shade_terminals = true,

            float_opts = {
                border = "curved",
            },
            highlights = {
                FloatBorder = {
                    guifg = "#7aa2f7",
                    guibg = "NONE",
                },
            },
        }
    }
}
