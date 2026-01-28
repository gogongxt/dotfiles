-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["<Leader>gS"] = {
      function()
        local gitsigns = require "gitsigns"
        local cache = require("gitsigns.cache").cache
        local buf = vim.api.nvim_get_current_buf()
        local file = vim.api.nvim_buf_get_name(buf)
        -- Check if file is untracked
        if file ~= "" then
          local result = vim.fn.systemlist("git status --porcelain " .. vim.fn.shellescape(file))
          if result and #result > 0 then
            local line = result[1]
            -- If untracked (starts with ??), add the file
            if line:match "^%?%?" then
              vim.fn.system("git add " .. vim.fn.shellescape(file))
              gitsigns.refresh()
              -- print("Added: " .. vim.fn.fnamemodify(file, ":t"))
              return
            end
          end
        end
        -- Check if there are unstaged hunks
        local bcache = cache[buf]
        local has_unstaged = bcache and bcache.hunks and #bcache.hunks > 0
        -- If has unstaged hunks, stage all; otherwise unstage all
        if has_unstaged then
          gitsigns.stage_buffer()
        else
          gitsigns.reset_buffer_index()
        end
      end,
      desc = "Toggle stage/unstage buffer",
    },
    ["<Leader>gj"] = {
      "<cmd>lua require('gitsigns').nav_hunk('next')<cr>",
      desc = "Hunk Next",
    },
    ["<Leader>gk"] = {
      "<cmd>lua require('gitsigns').nav_hunk('prev')<cr>",
      desc = "Hunk Prev",
    },
    ["<Leader>gJ"] = {
      "<cmd>lua require('gitsigns').nav_hunk('next',{target='staged'})<cr>",
      desc = "Hunk Next(staged)",
    },
    ["<Leader>gK"] = {
      "<cmd>lua require('gitsigns').nav_hunk('prev',{target='staged'})<cr>",
      desc = "Hunk Prev(staged)",
    },
    ["<Leader>gB"] = {
      "",
      desc = "Git Blame",
    },
    ["<Leader>gBw"] = { "<cmd>BlameToggle window<cr>", desc = "Blame window" },
    ["<Leader>gBv"] = { "<cmd>BlameToggle virtual<cr>", desc = "Blame virtual" },
    ["<Leader>gd"] = { "<cmd>lua require('gitsigns').diffthis()<cr>", desc = "Git Giff" }, -- see diff unstaged
    ["<Leader>gD"] = { function() require("gitsigns").diffthis "~" end, desc = "Git Giff(staged)" }, -- see diff all include unstaged and staged
    ["<A-g>"] = { "<cmd>lua require('plugins.user.my_funcs').git_gitui_toggle()<cr>", desc = "gitui" },
    ["<Leader>gP"] = { "<cmd>lua require('gitsigns').preview_hunk()<cr>", desc = "Hunk Preview Hover" },
    ["<Leader>gi"] = { "<cmd>lua require('gitsigns').blame_line()<cr>", desc = "Line Info" },
    ["<Leader>gq"] = { "<cmd>lua require('gitsigns').setqflist()<cr>", desc = "Git Quickfix" },
    ["<Leader>gQ"] = { "<cmd>lua require('gitsigns').setqflist('all')<cr>", desc = "Git Quickfix(all files)" },
  },
  t = {
    ["<A-g>"] = { "<cmd>lua require('plugins.user.my_funcs').git_gitui_toggle()<cr>", desc = "gitui" },
  },
}

return {
  {
    "FabijanZulj/blame.nvim",
    config = function() require("blame").setup() end,
  },
  {
    "f-person/git-blame.nvim",
    -- load the plugin at startup
    event = "VeryLazy",
    -- Because of the keys part, you will be lazy loading this plugin.
    -- The plugin wil only load once one of the keys is used.
    -- If you want to load the plugin at startup, add something like event = "VeryLazy",
    -- or lazy = false. One of both options will work.
    opts = {
      -- your configuration comes here
      -- for example
      enabled = true, -- if you want to enable the plugin
      message_template = " [<date>] [<author>]:<summary>  <<sha>>", -- template for the blame message, check the Message template section for more options
      date_format = "%Y-%m-%d %H:%M:%S", -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },
    config = function(_, opts)
      require("gitblame").setup(opts)
      vim.g.gitblame_message_when_not_committed = "" -- set null when nothing commit
    end,
  },
  {
    "sindrets/diffview.nvim",
    config = function()
      -- Lua
      require("diffview").setup {
        view = {
          -- Configure the layout and behavior of different types of views.
          -- Available layouts:
          --  'diff1_plain'
          --    |'diff2_horizontal'
          --    |'diff2_vertical'
          --    |'diff3_horizontal'
          --    |'diff3_vertical'
          --    |'diff3_mixed'
          --    |'diff4_mixed'
          -- For more info, see |diffview-config-view.x.layout|.
          default = {
            -- Config for changed files, and staged files in diff views.
            layout = "diff2_horizontal",
            disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view.
            winbar_info = true, -- See |diffview-config-view.x.winbar_info|
          },
          merge_tool = {
            -- Config for conflicted files in diff views during a merge or rebase.
            layout = "diff3_mixed",
            disable_diagnostics = true, -- Temporarily disable diagnostics for diff buffers while in the view.
            winbar_info = true, -- See |diffview-config-view.x.winbar_info|
          },
          file_history = {
            -- Config for changed files in file history views.
            layout = "diff2_horizontal",
            disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view.
            winbar_info = true, -- See |diffview-config-view.x.winbar_info|
          },
        },
      }
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      local original_on_attach = opts.on_attach
      opts.on_attach = function(bufnr)
        -- run default on_attach function
        if original_on_attach then original_on_attach(bufnr) end
        -- continue with customizations such as deleting mappings
        vim.keymap.del("n", "<Leader>gS", { buffer = bufnr })
      end
    end,
  },
}
