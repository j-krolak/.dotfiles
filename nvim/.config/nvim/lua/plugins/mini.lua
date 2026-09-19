return {
	"nvim-mini/mini.nvim",
	config = function()
		local statusline = require "mini.statusline"
		statusline.setup {
			use_icons = true,
			content = {
				active = function()
					local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
					local git = statusline.section_git { trunc_width = 40 }
					local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
					local lsp = statusline.section_lsp { trunc_width = 75 }
					local filename = statusline.section_filename { trunc_width = 140 }
					local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
					local location = '%l:%v %L:%{virtcol("$") - 1}'

					return statusline.combine_groups {
						{ hl = mode_hl,                 strings = { mode } },
						{ hl = "MiniStatuslineDevinfo", strings = { git, diagnostics, lsp } },
						"%<",
						{ hl = "MiniStatuslineFilename", strings = { filename } },
						"%=",
						{ hl = "MiniStatuslineDevinfo",  strings = { fileinfo, location } },
					}
				end,
			},
		}
		require("mini.comment")
	end
}
