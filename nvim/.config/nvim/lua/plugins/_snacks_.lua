-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    -- ["<Leader>z"] = { "<cmd>lua Snacks.zen()<cr>", desc = "Focus Current Buffer" },
    -- ["<Leader>Z"] = { "<cmd>lua Snacks.zen.zoom()<cr>", desc = "Focus Current Buffer Zoom" },

    -- ["<Leader>fw"] = { function() require("snacks").picker.grep { need_search = "123" } end, desc = "Find words" },
    -- ["<Leader>fW"] = {
    --   function() require("snacks").picker.grep { hidden = true, ignored = true } end,
    --   desc = "Find words in all files",
    -- },
  },
}

-- local keymap = vim.keymap.set
-- keymap(
--   { "n" },
--   "<Leader>fw",
--   function() require("snacks").picker.grep { need_search = "123" } end,
--   { desc = "Find words" }
-- )
-- keymap({ "n" }, "<Leader>gk", "<cmd>lua require('gitsigns').nav_hunk('prev')<cr>", { desc = "Hunk prev" })

return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          -- ["<Leader>fs"] = { function() require("snacks").picker.smart() end, desc = "Find buffers/recent/files" },
          ["<Leader>fs"] = { function() require("snacks").picker.grep { regex = true } end, desc = "Find string" },
          ["<Leader>fS"] = {
            function() require("snacks").picker.grep { regex = true, hidden = true, ignored = true } end,
            desc = "Find string in all files",
          },
          ["<Leader>fw"] = {
            function() require("snacks").picker.grep_word { regex = true, live = true } end,
            desc = "Find words",
          },
          ["<Leader>fW"] = {
            function() require("snacks").picker.grep_word { regex = true, live = true, hidden = true, ignored = true } end,
            desc = "Find words in all files",
          },
          ["<Leader>fr"] = { function() require("snacks").picker.recent() end, desc = "Find recent files" },
          ["<Leader>fR"] = {
            function() require("snacks").picker.recent { filter = { cwd = true } } end,
            desc = "Find old files (cwd)",
          },
          ["<Leader>fp"] = { function() require("snacks").picker.projects() end, desc = "Find projects" },
          ["<Leader>fy"] = { function() require("snacks").picker.registers() end, desc = "Find registers" },
          ["<Leader>fn"] = { "<cmd>Noice pick<cr>", desc = "Find themes" },
          ["<Leader>fc"] = { function() require("snacks").picker.command_history() end, desc = "Find commands history" },
          ["<Leader>fC"] = { function() require("snacks").picker.commands() end, desc = "Find all commands" },
          ["<Leader>ut"] = { function() require("snacks").picker.colorschemes() end, desc = "Find themes" },
          -- maps.n["<Leader>fw"] = { function() require("snacks").picker.grep() end, desc = "Find words" }
          -- maps.n["<Leader>fW"] = {
          --   function() require("snacks").picker.grep { hidden = true, ignored = true } end,
          --   desc = "Find words in all files",
          -- }
          ["<Leader>fT"] = {
            function()
              if not package.loaded["todo-comments"] then -- make sure to load todo-comments
                require("lazy").load { plugins = { "todo-comments.nvim" } }
              end
              require("snacks").picker.todo_comments { keywords = { "TODO" } }
            end,
            desc = "Find TODO",
          },
          ["<Leader>ft"] = {
            function()
              if not package.loaded["todo-comments"] then -- make sure to load todo-comments
                require("lazy").load { plugins = { "todo-comments.nvim" } }
              end
              require("snacks").picker.todo_comments()
            end,
            desc = "Find ALL TODO FIXME NOTE...",
          },
        },
        v = {
          ["<Leader>fw"] = {
            function() require("snacks").picker.grep_word { regex = true, live = true } end,
            desc = "Find words",
          },
          ["<Leader>fW"] = {
            function() require("snacks").picker.grep_word { regex = true, live = true, hidden = true, ignored = true } end,
            desc = "Find words in all files",
          },
        },
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        win = {
          input = {
            keys = {
              ["<C-j>"] = { "history_forward", mode = { "i", "n" } },
              ["<C-k>"] = { "history_back", mode = { "i", "n" } },
              ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
              ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
              ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
              ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
            },
          },
        },
      },
      notifier = {
        enabled = false,
      },
      image = {
        enabled = true,
        -- TODO: need to toggle doc image show inline
        -- https://github.com/folke/snacks.nvim/issues/1739
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = true,
          max_width = 80,
          max_height = 40,
          -- Set to `true`, to conceal the image text when rendering inline.
          -- (experimental)
          ---@param lang string tree-sitter language
          ---@param type snacks.image.Type image type
          conceal = function(lang, type)
            -- only conceal math expressions
            return type == "math"
          end,
        },
      },
      -- input = {
      --   enabled = true,
      -- },
      -- zen = {
      --   toggles = {
      --     dim = false,
      --     git_signs = true,
      --     mini_diff_signs = true,
      --     diagnostics = true,
      --     inlay_hints = true,
      --   },
      --   show = {
      --     statusline = true, -- can only be shown when using the global statusline
      --     tabline = true,
      --   },
      --   ---@type snacks.win.Config
      --   win = { style = "zen" },
      --   --- Callback when the window is opened.
      --   ---@param win snacks.win
      --   on_open = function(win) end,
      --   --- Callback when the window is closed.
      --   ---@param win snacks.win
      --   on_close = function(win) end,
      --   --- Options for the `Snacks.zen.zoom()`
      --   ---@type snacks.zen.Config
      --   zoom = {
      --     toggles = {},
      --     show = { statusline = true, tabline = true },
      --     win = {
      --       backdrop = false,
      --       width = 0, -- full width
      --     },
      --   },
      -- },
    },
  },
}
