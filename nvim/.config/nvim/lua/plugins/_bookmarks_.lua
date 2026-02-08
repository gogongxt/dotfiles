-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  -- {
  --   -- 书签插件
  --   "tomasky/bookmarks.nvim",
  --   event = "VimEnter",
  --   config = function()
  --     require("bookmarks").setup {
  --       -- sign_priority = 8,  --set bookmark sign priority to cover other sign
  --       save_file = vim.fn.expand "$HOME/.bookmarks", -- bookmarks save file path
  --       keywords = {
  --         ["@t"] = "🔥", -- mark annotation startswith @t ,signs this icon as `Todo`
  --         ["@w"] = "⚠️", -- mark annotation startswith @w ,signs this icon as `Warn`
  --         ["@f"] = "📌", -- mark annotation startswith @f ,signs this icon as `Fix`
  --         ["@n"] = "🧠", -- mark annotation startswith @n ,signs this icon as `Note`
  --       },
  --       on_attach = function(bufnr)
  --         local bm = require "bookmarks"
  --         local map = vim.keymap.set
  --         map("n", "mm", bm.bookmark_toggle) -- add or remove bookmark at current line
  --         map("n", "mi", bm.bookmark_ann) -- add or edit mark annotation at current line
  --         map("n", "mc", bm.bookmark_clean) -- clean all marks in local buffer
  --         map("n", "mn", bm.bookmark_next) -- jump to next mark in local buffer
  --         map("n", "mj", bm.bookmark_next) -- jump to next mark in local buffer
  --         map("n", "mp", bm.bookmark_prev) -- jump to previous mark in local buffer
  --         map("n", "mk", bm.bookmark_prev) -- jump to previous mark in local buffer
  --         map("n", "mq", bm.bookmark_list) -- show marked file list in quickfix window
  --
  --         -- TODO: add picker show
  --         -- map("n", "ml", bm.bookmark_list) -- show marked file list in picker
  --       end,
  --     }
  --   end,
  -- },
  {
    "gogongxt/bookmarks.nvim",
    -- event = "VeryLazy",
    dependencies = {
      { "folke/snacks.nvim" }, -- snacks picker support (alternative to telescope)
    },
    config = function()
      -- check the "./lua/bookmarks/default-config.lua" file for all the options
      local opts = {
        picker = {
          -- type = "telescope", -- or "telescope" (default)
          type = "snacks", -- or "telescope" (default)
        },
        signs = {
          -- Sign mark icon and color in the gutter
          mark = {
            icon = "󰃁",
            color = "red",
            line_bg = "#572626",
          },
          desc_format = function(bookmark) return bookmark.name end,
        },
      }
      require("bookmarks").setup(opts) -- you must call setup to init sqlite db
      -- remove the line background color scheme
      -- vim.cmd [[
      --   function! BookmarkColor()
      --     hi BookmarksNvimLine guibg=NONE
      --   endfunction
      --   augroup BookmarkCustomHighlight
      --     autocmd!
      --     autocmd ColorScheme * call BookmarkColor()
      --   augroup END
      --   call BookmarkColor()
      -- ]]
    end,
    keys = {
      { "mm", "<cmd>BookmarksMark<cr>", mode = { "n", "v" } },
      { "mn", "<cmd>BookmarksGotoNext<cr>", mode = { "n", "v" } },
      { "mN", "<cmd>BookmarksGotoNextInList<cr>", mode = { "n", "v" } },
      { "mp", "<cmd>BookmarksGotoPrev<cr>", mode = { "n", "v" } },
      { "mP", "<cmd>BookmarksGotoPrevInList<cr>", mode = { "n", "v" } },
      { "ml", "<cmd>BookmarksGoto<cr>", mode = { "n", "v" } },
      { "mL", "<cmd>BookmarksLists<cr>", mode = { "n", "v" } },
      { "mN", "<cmd>BookmarksNewList<cr>", mode = { "n", "v" } },
      { "mo", "<cmd>BookmarksTree<cr>", mode = { "n", "v" } },
      { "m?", "<cmd>BookmarksCommands<cr>", mode = { "n", "v" } },
    },
  },
}
