return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs                        = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signs_staged                 = {
        add          = { text = '┃' },
        change       = { text = '┃' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      signs_staged_enable          = true,
      signcolumn                   = true,  -- Toggle with `:Gitsigns toggle_signs`
      numhl                        = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl                       = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff                    = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir                 = {
        follow_files = true
      },
      auto_attach                  = true,
      attach_to_untracked          = false,
      current_line_blame           = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts      = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
        use_focus = true,
      },
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
      sign_priority                = 6,
      update_debounce              = 100,
      status_formatter             = nil,   -- Use default
      max_file_length              = 40000, -- Disable if file is longer than this (in lines)
      preview_config               = {
        -- Options passed to nvim_open_win
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },

      on_attach                    = function(bufnr)
        local gs = package.loaded.gitsigns

        vim.keymap.set('n', ']h', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, { buffer = bufnr, desc = 'Next git hunk' })

        vim.keymap.set('n', '[h', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, { buffer = bufnr, desc = 'Previous git hunk' })

        vim.keymap.set('n', '<leader>hd', function()
          if vim.wo.diff then
            vim.cmd('diffoff!')
          else
            require('gitsigns').diffthis()
          end
        end, {
          buffer = bufnr,
          desc = 'Toggle git diff',
        })

        vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {
          buffer = bufnr,
          desc = 'Stage git hunk',
        })

        vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {
          buffer = bufnr,
          desc = 'Reset git hunk',
        })

        vim.keymap.set('n', '<leader>hb', gs.blame_line, {
          buffer = bufnr,
          desc = 'Blame line',
        })

        vim.keymap.set('n', '<leader>hp', gs.preview_hunk, {
          buffer = bufnr,
          desc = 'Preview chunk',
        })
 
      end,
    }
  },
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      {
        "<leader>gd",
        function()
          local lifecycle = require("codediff.ui.lifecycle")
          local session = require("codediff.ui.lifecycle.session")

          -- Close an already open diff tab, otherwise open a new one.
          for tabpage in pairs(session.get_active_diffs()) do
            if vim.api.nvim_tabpage_is_valid(tabpage) then
              vim.api.nvim_set_current_tabpage(tabpage)
              lifecycle.close(tabpage)
              return
            end
          end

          vim.cmd("CodeDiff")
        end,
        desc = "CodeDiff: toggle",
      },
      { "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "CodeDiff: file history" },
    },
    opts = {
      keymaps = {
        view = {
          next_file = "<Tab>",
          prev_file = "<S-Tab>",
        },
      },
    },
  },
  -- {
  --   "dlyongemallo/diffview-plus.nvim",
  --   cmd = {
  --     "DiffviewOpen",
  --     "DiffviewClose",
  --     "DiffviewToggleFiles",
  --     "DiffviewFocusFiles",
  --     "DiffviewFileHistory",
  --   },
  --   keys = {
  --     { "<leader>gd", "<cmd>DiffviewToggle<cr>",      desc = "Diffview: open" },
  --     { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: file history" },
  --   },
  --   opts = {
  --     file_panel = {
  --       listing_style = "tree",
  --       win_config = {
  --         width = 45,
  --         position = "right",
  --       },
  --     },
  --     view = {
  --       default = {
  --         layout = "diff1_inline",
  --       },
  --       inline = {
  --         style = "unified",
  --       },
  --     },
  --   },
  -- },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      -- "dlyongemallo/diffview-plus.nvim", -- optional - Diff integration

      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
      "folke/snacks.nvim",             -- optional
    },
    keys = {
      { "<leader>ng", "<cmd>Neogit<cr>", desc = "Open neogit" }
    }
  }
}
