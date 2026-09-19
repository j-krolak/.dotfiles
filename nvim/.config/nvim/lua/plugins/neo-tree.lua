return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false, -- Load immediately on startup
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    {
      dir = vim.fn.stdpath("config") .. "/plugins/neo-tree-dotnet.nvim",
      name = "neo-tree-dotnet.nvim",
    },
  },
  config = function()
    require("neo-tree").setup({
      sources = { "filesystem", "buffers", "git_status", "dotnet_solution" },
      commands = {
        toggle_dotnet_view = function()
          require("neo-tree-dotnet").toggle()
        end,
      },
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem", display_name = " Files " },
          { source = "dotnet_solution", display_name = " Solution " },
        },
      },
      dotnet_solution = {
        project_files = "filesystem",
        follow_current_file = { enabled = true },
        window = {
          position = "right",
          mappings = { ["<Tab>"] = "toggle_dotnet_view" },
        },
      },
      default_component_configs = {
        file_size = { enabled = false },
        last_modified = { enabled = false },
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
        },

        filtered_items = {
          hide_dotfiles = false,
        },

        window = {
          position = "right",
          mappings = {
            ["R"] = "easy_dotnet_new_item",
            ["<Tab>"] = "toggle_dotnet_view",
          },
        },

        commands = {
          easy_dotnet_new_item = function(state)
            local node = state.tree:get_node()
            local path = node.type == "directory" and node.path or vim.fs.dirname(node.path)
            require("easy-dotnet").create_item(path)
          end,
        },
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.opt_local.number = true
            vim.opt_local.relativenumber = true
          end,
        },
        {
          event = "file_opened",
          handler = function()
            -- Auto close via command
            require("neo-tree.command").execute({ action = "close" })
          end
        },
      },
    })

    -- Keymap
    vim.keymap.set('n', '<leader>e', function()
      require('neo-tree-dotnet').toggle_panel()
    end, { desc = 'Toggle Neo-tree panel (remember view)' })
    vim.keymap.set('n', '<leader>ee', function()
      require('neo-tree-dotnet').toggle_panel()
    end, { desc = 'Toggle Neo-tree panel (remember view)' })
    vim.keymap.set('n', '<leader>E', function()
      require('neo-tree-dotnet').toggle()
    end, { desc = 'Neo-tree: files / .NET solution' })
  end,
}
