return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function hunk(direction, diff_key, opts)
          return function()
            if vim.wo.diff then
              vim.cmd.normal({ diff_key, bang = true })
            else
              gs.nav_hunk(direction, opts)
            end
          end
        end
        local next_hunk, prev_hunk = hunk('next', ']c'), hunk('prev', '[c')

        vim.keymap.set('n', ']h', next_hunk, { buffer = bufnr, desc = 'Next git hunk' })
        vim.keymap.set('n', '[h', prev_hunk, { buffer = bufnr, desc = 'Previous git hunk' })
        vim.keymap.set('n', '<leader>]c', next_hunk, { buffer = bufnr, desc = 'Next git hunk' })
        vim.keymap.set('n', '<leader>[c', prev_hunk, { buffer = bufnr, desc = 'Previous git hunk' })
        vim.keymap.set('n', ']<End>', hunk('next', ']c', { preview = true }),
          { buffer = bufnr, desc = 'Next git hunk (preview)' })
        vim.keymap.set('n', '[<Home>', hunk('prev', '[c', { preview = true }),
          { buffer = bufnr, desc = 'Previous git hunk (preview)' })

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        local function range()
          return { vim.fn.line('.'), vim.fn.line('v') }
        end

        map('n', '<leader>gD', function()
          if vim.wo.diff then
            vim.cmd('diffoff!')
          else
            gs.diffthis()
          end
        end, 'Toggle git diff (split)')
        map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>gi', gs.preview_hunk_inline, 'Preview hunk inline')
        map('n', '<leader>gb', gs.blame_line, 'Blame line')
        map('n', '<leader>gB', gs.toggle_current_line_blame, 'Toggle inline blame')
        map('n', '<leader>gw', gs.toggle_word_diff, 'Toggle word diff')
        map('n', '<leader>gs', gs.stage_hunk, 'Stage hunk')
        map('v', '<leader>gs', function() gs.stage_hunk(range()) end, 'Stage selected lines')
        map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('v', '<leader>gr', function() gs.reset_hunk(range()) end, 'Reset selected lines')
        map('n', '<leader>gS', gs.stage_buffer, 'Stage buffer')
        map('n', '<leader>gR', gs.reset_buffer, 'Reset buffer')
        map('n', '<leader>gq', gs.setqflist, 'Hunks to quickfix')
        map({ 'o', 'x' }, 'ih', gs.select_hunk, 'Inner hunk')
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
      -- Moves default to DiffChange, which the theme keeps olive like inserts.
      highlights = { line_move = "#264f78" },
      keymaps = {
        view = {
          next_file = "<Tab>",
          prev_file = "<S-Tab>",
        },
      },
    },
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    keys = {
      { "<leader>ng", "<cmd>Neogit<cr>", desc = "Open neogit" }
    }
  }
}
