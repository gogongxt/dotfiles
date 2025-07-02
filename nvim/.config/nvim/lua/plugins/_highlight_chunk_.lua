-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- use snacks highlight chunk to subtitute hlchunk.nvim
-- chunk config : https://github.com/folke/snacks.nvim/blob/main/docs/indent.md

return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      indent = {
        enabled = true,
        indent = {
          priority = 1,
          enabled = true, -- enable indent guides
          char = "▏", -- 1. │  2. ▏
          only_scope = false, -- only show indent guides of the scope
          only_current = false, -- only show indent guides in the current window
          hl = "SnacksIndent", ---@type string|string[] hl groups for indent guides
          -- can be a list of hl groups to cycle through
          -- hl = {
          --     "SnacksIndent1",
          --     "SnacksIndent2",
          --     "SnacksIndent3",
          --     "SnacksIndent4",
          --     "SnacksIndent5",
          --     "SnacksIndent6",
          --     "SnacksIndent7",
          --     "SnacksIndent8",
          -- },
        },
        vim.api.nvim_set_hl(0, "MyChunkColor", { fg = "#CB8764" }),
        scope = {
          enabled = true, -- enable highlighting the current scope
          priority = 200,
          char = "▏",
          underline = false, -- underline the start of the scope
          only_current = false, -- only show scope in the current window
          hl = "MyChunkColor", ---@type string|string[] hl group for scopes
        },
        chunk = {
          -- when enabled, scopes will be rendered as chunks, except for the
          -- top-level scope which will be rendered as a scope.
          enabled = true,
          -- only show chunk scopes in the current window
          only_current = false,
          priority = 200,
          hl = "MyChunkColor", ---@type string|string[] hl group for chunk scopes
          char = {
            -- corner_top = "┌",
            -- corner_bottom = "└",
            corner_top = "╭",
            corner_bottom = "╰",
            horizontal = "─",
            vertical = "│",
            arrow = ">",
          },
        },
      },
    },
  },
  -- {
  --   "gxt-kt/hlchunk.nvim",
  --   event = { "BufReadPre", "BufNewFile" },
  --   enabled = false,
  --   config = function()
  --     require("hlchunk").setup {
  --       chunk = {
  --         enable = true,
  --         use_treesitter = true,
  --         max_file_size = 1024 * 1024,
  --         exclude_filetypes = {
  --           aerial = true,
  --           dashboard = true,
  --         },
  --         chars = {
  --           horizontal_line = "─",
  --           vertical_line = "│",
  --           left_top = "╭",
  --           left_bottom = "╰",
  --           right_arrow = ">",
  --         },
  --         style = {
  --           { fg = "#CB8764" },
  --         },
  --         error_sign = true,
  --         duration = 150,
  --         delay = 50,
  --       },
  --       indent = {
  --         enable = true, --
  --         -- chars = { "│", "¦", "┆", "┊" },
  --         chars = { "▏" },
  --         -- chars = { " ", " ", " ", " " },
  --         use_treesitter = false,
  --         style = {
  --           -- { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") }
  --           { fg = "#51576e" },
  --         },
  --       },
  --       line_num = {
  --         enable = false,
  --         use_treesitter = true,
  --         style = "#806d9c",
  --       },
  --       blank = {
  --         enable = false,
  --         chars = {
  --           "․",
  --         },
  --         style = {
  --           vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID "Whitespace"), "fg", "gui"),
  --         },
  --       },
  --     }
  --   end,
  -- },
}
