-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "gogongxt/modes.nvim",
  config = function()
    require("modes").setup {
      -- colors = {
      --   bg = "", -- Optional bg param, defaults to Normal hl group
      --   copy = "#f5c359",
      --   delete = "#c75c6a",
      --   change = "#c75c6a", -- Optional param, defaults to delete
      --   format = "#c79585",
      --   insert = "#78ccc5",
      --   replace = "#245361",
      --   select = "#9745be", -- Optional param, defaults to visual
      --   visual = "#9745be",
      -- },
      colors = {
        copy = "#78ccc5",
        delete = "#78ccc5",
        change = "#78ccc5",
        format = "#78ccc5",
        insert = "#78ccc5",
        replace = "#78ccc5",
        select = "#78ccc5",
        visual = "#78ccc5",
      },

      -- Set opacity for cursorline and number background
      line_opacity = {
        copy = 0.3,
        delete = 0.3,
        change = 0.3,
        format = 0.3,
        insert = 0.3,
        replace = 0.3,
        select = 0.3,
        visual = 0.3,
      },

      -- Enable cursor highlights
      set_cursor = false,

      -- Enable cursorline initially, and disable cursorline for inactive windows
      -- or ignored filetypes
      set_cursorline = false,

      -- Enable line number highlights to match cursorline
      set_number = false,

      -- Enable sign column highlights to match cursorline
      set_signcolumn = false,

      -- Disable modes highlights for specified filetypes
      -- or enable with prefix "!" if otherwise disabled (please PR common patterns)
      -- Can also be a function fun():boolean that disables modes highlights when true
      ignore = { "NvimTree", "TelescopePrompt", "!minifiles" },
    }
  end,
}
