-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- use snacks scroll to subtituteneoscroll.nvim
-- scroll config : https://github.com/folke/snacks.nvim/blob/main/docs/scroll.md

return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      scroll = {
        -- your scroll configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
    },
  },
  {
    "karb94/neoscroll.nvim",
    enabled = false,
    config = function()
      require("neoscroll").setup {
        mappings = { -- Keys to be mapped to their corresponding default scrolling animation
          "<C-u>",
          "<C-d>",
          "<C-b>",
          "<C-f>",
          "<C-y>",
          -- "<C-e>", -- <c-e> map to smart-splits
          "zt",
          "zz",
          "zb",
        },
        hide_cursor = false, -- Hide cursor while scrolling
        stop_eof = true, -- Stop at <EOF> when scrolling downwards
        respect_scrolloff = false, -- Stop scrolling when the cursor reaches the scrolloff margin of the file
        cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
        easing = "linear", -- Default easing function ("linear", "quadratic", "cubic", "quartic", "quintic", "circular", "sine")
        pre_hook = nil, -- Function to run before the scrolling animation starts
        post_hook = nil, -- Function to run after the scrolling animation ends
        performance_mode = false, -- Disable "Performance Mode" on all buffers.
        ignored_events = { -- Events ignored while scrolling
          "WinScrolled",
          "CursorMoved",
        },
      }
    end,
  },
}
