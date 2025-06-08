-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    config = function()
      require("flash").setup {
        modes = {
          search = {
            enabled = false,
          },
          char = {
            enabled = false,
          },
        },
      }
    end,
  },
  {
    "phaazon/hop.nvim",
    branch = "v2", -- optional but strongly recommended
    event = "VeryLazy",
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require("hop").setup { keys = "etovxqpdygfblzhckisuran" }
    end,
    init = function()
      local hop = require "hop"
      local directions = require("hop.hint").HintDirection
      vim.keymap.set(
        "",
        "f",
        function() hop.hint_char1 { direction = directions.AFTER_CURSOR, current_line_only = true } end,
        { remap = true }
      )
      vim.keymap.set(
        "",
        "F",
        function() hop.hint_char1 { direction = directions.BEFORE_CURSOR, current_line_only = true } end,
        { remap = true }
      )
      vim.keymap.set(
        "",
        "t",
        function()
          hop.hint_char1 {
            direction = directions.AFTER_CURSOR,
            current_line_only = false,
            hint_offset = 0,
          }
        end,
        { remap = true }
      )
      vim.keymap.set(
        "",
        "T",
        function()
          hop.hint_char1 {
            direction = directions.BEFORE_CURSOR,
            current_line_only = false,
            hint_offset = 0,
          }
        end,
        { remap = true }
      )
    end,
  },
}
