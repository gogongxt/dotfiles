-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "nvim-telescope/telescope-live-grep-args.nvim",
        version = "^1.0.0",
      },
    },
    config = function() require("telescope").load_extension "live_grep_args" end,
    opts = function(_, opts)
      -- local _, actions = pcall(require, "telescope.actions")
      local actions = require "telescope.actions"
      opts.defaults.mappings = {
        i = {
          ["<C-j>"] = actions.cycle_history_next,
          ["<C-k>"] = actions.cycle_history_prev,
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,
        },
        n = {
          ["<C-j>"] = actions.cycle_history_next,
          ["<C-k>"] = actions.cycle_history_prev,
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,
        },
      }
    end,
  },
  {
    "AckslD/nvim-neoclip.lua",
    dependencies = {
      { "kkharji/sqlite.lua", module = "sqlite" },
      -- you'll need at least one of these
      -- {'nvim-telescope/telescope.nvim'},
      -- {'ibhagwan/fzf-lua'},
    },
    config = function()
      require("neoclip").setup {
        enable_persistent_history = true,
        keys = {
          telescope = {
            i = {
              ["<C-j>"] = require("telescope.actions").cycle_history_next,
              ["<C-k>"] = require("telescope.actions").cycle_history_prev,
              ["<C-n>"] = require("telescope.actions").move_selection_next,
              ["<C-p>"] = require("telescope.actions").move_selection_previous,
              paste = "<CR>",
              delete = "<c-d>", -- delete an entry
              edit = "<c-e>", -- edit an entry
              custom = {},
            },
            n = {
              ["<C-j>"] = require("telescope.actions").cycle_history_next,
              ["<C-k>"] = require("telescope.actions").cycle_history_prev,
              ["<C-n>"] = require("telescope.actions").move_selection_next,
              ["<C-p>"] = require("telescope.actions").move_selection_previous,
              paste = "<CR>",
              delete = "d", -- delete an entry
              edit = "e", -- edit an entry
              custom = {},
            },
          },
        },
      }
    end,
  },
}

-- Telescope projects
