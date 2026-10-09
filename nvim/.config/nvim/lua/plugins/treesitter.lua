return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- main branch needs the `tree-sitter` CLI + a C compiler to build parsers
		build = function()
			if vim.fn.executable("tree-sitter") == 1 then
				vim.cmd("TSUpdate")
			end
		end,
		dependencies = { "mason-org/mason.nvim" },
		lazy = false,
		config = function()
			require("nvim-treesitter").setup()

			-- xml covers .csproj/.slnx/.props/.targets
			local want = { "c", "cpp", "c_sharp", "xml", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" }

			local function install_missing()
				if vim.fn.executable("cc") == 0 and vim.fn.executable("gcc") == 0 and vim.fn.executable("clang") == 0 then
					vim.notify("treesitter: no C compiler found (install gcc/clang), parsers not built", vim.log.levels.WARN)
					return
				end
				local have = require("nvim-treesitter.config").get_installed()
				local todo = vim.iter(want):filter(function(p)
					return not vim.tbl_contains(have, p)
				end):totable()
				if #todo > 0 then
					require("nvim-treesitter").install(todo)
				end
			end

			-- No root/package manager needed: Mason ships a prebuilt tree-sitter binary
			-- and puts it on PATH.
			if vim.fn.executable("tree-sitter") == 1 then
				install_missing()
			else
				require("mason-registry").refresh(function()
					local ok, pkg = pcall(require("mason-registry").get_package, "tree-sitter-cli")
					if not ok then
						return
					end
					pkg:once("install:success", vim.schedule_wrap(install_missing))
					if not pkg:is_installed() then
						pkg:install()
					else
						vim.schedule(install_missing)
					end
				end)
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					if not pcall(vim.treesitter.start, args.buf) then
						return
					end
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			multiline_threshold = 1, -- collapse each context to a single line (IDE-like)
		},
		config = function(_, opts)
			require("treesitter-context").setup(opts)

			local function set_hl()
				vim.api.nvim_set_hl(0, "TreesitterContext", { link = "Normal" })
				vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { link = "LineNr" })
				vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#3c3c3c" })
			end
			set_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })
		end,
	}
}
