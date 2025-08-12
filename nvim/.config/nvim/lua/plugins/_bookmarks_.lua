-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- vim.keymap.set({ "n", "v" }, "mm", "BookmarksMark", { desc = "Booksmark Toggle" })
-- vim.keymap.set({ "n", "v" }, "ml", "BookmarksGoto", { desc = "Booksmark Toggle" })
-- vim.keymap.set({ "n", "v" }, "mL", "BookmarksLists", { desc = "Booksmark Toggle" })
-- vim.keymap.set({ "n", "v" }, "mt", "BookmarksTree", { desc = "Booksmark Toggle" })
-- vim.keymap.set({ "n", "v" }, "mm", "<cmd>BookmarksMark<cr>", { desc = "Mark current line into active BookmarkList." })
-- vim.keymap.set({ "n", "v" }, "mo", "<cmd>BookmarksGoto<cr>", { desc = "Go to bookmark at current active BookmarkList" })
-- vim.keymap.set({ "n", "v" }, "ma", "<cmd>BookmarksCommands<cr>", { desc = "Find and trigger a bookmark command." })

return {
  {
    -- 书签插件
    "tomasky/bookmarks.nvim",
    event = "VimEnter",
    config = function()
      require("bookmarks").setup {
        -- sign_priority = 8,  --set bookmark sign priority to cover other sign
        save_file = vim.fn.expand "$HOME/.bookmarks", -- bookmarks save file path
        keywords = {
          ["@t"] = "🔥", -- mark annotation startswith @t ,signs this icon as `Todo`
          ["@w"] = "⚠️", -- mark annotation startswith @w ,signs this icon as `Warn`
          ["@f"] = "📌", -- mark annotation startswith @f ,signs this icon as `Fix`
          ["@n"] = "🧠", -- mark annotation startswith @n ,signs this icon as `Note`
        },
        on_attach = function(bufnr)
          local bm = require "bookmarks"
          local map = vim.keymap.set
          map("n", "mm", bm.bookmark_toggle) -- add or remove bookmark at current line
          map("n", "mi", bm.bookmark_ann) -- add or edit mark annotation at current line
          map("n", "mc", bm.bookmark_clean) -- clean all marks in local buffer
          map("n", "mn", bm.bookmark_next) -- jump to next mark in local buffer
          map("n", "mj", bm.bookmark_next) -- jump to next mark in local buffer
          map("n", "mp", bm.bookmark_prev) -- jump to previous mark in local buffer
          map("n", "mk", bm.bookmark_prev) -- jump to previous mark in local buffer
          map("n", "mq", bm.bookmark_list) -- show marked file list in quickfix window

          -- TODO: add picker show
          -- map("n", "ml", bm.bookmark_list) -- show marked file list in picker
        end,
      }
    end,
  },
  -- {
  --   "LintaoAmons/bookmarks.nvim",
  --   -- pin the plugin at specific version for stability
  --   -- backup your bookmark sqlite db when there are breaking changes (major version change)
  --   tag = "3.2.0",
  --   dependencies = {
  --     { "kkharji/sqlite.lua" },
  --     { "nvim-telescope/telescope.nvim" }, -- currently has only telescopes supported, but PRs for other pickers are welcome
  --     { "stevearc/dressing.nvim" }, -- optional: better UI
  --     { "GeorgesAlkhouri/nvim-aider" }, -- optional: for Aider integration
  --   },
  --   config = function()
  --     local opts = {} -- check the "./lua/bookmarks/default-config.lua" file for all the options
  --     require("bookmarks").setup(opts) -- you must call setup to init sqlite db
  --   end,
  -- },
}
