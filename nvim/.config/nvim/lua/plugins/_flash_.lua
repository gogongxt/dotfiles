-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = { enabled = false },
        char = { enabled = false },
      },
    },
    keys = function()
      local function hop_like(forward, offset)
        return function()
          require("flash").jump {
            search = {
              forward = forward,
              wrap = false,
              multi_window = false,
              max_length = 1,
              mode = function(str) return "\\V" .. str end,
            },
            jump = {
              offset = offset,
            },
          }
        end
      end

      return {
        { "<Leader>s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
        { "f", mode = { "n", "x", "o" }, hop_like(true, 0), desc = "Hop-like f" },
        { "F", mode = { "n", "x", "o" }, hop_like(false, 0), desc = "Hop-like F" },
        { "t", mode = { "n", "x", "o" }, hop_like(true, -1), desc = "Hop-like t" },
        { "T", mode = { "n", "x", "o" }, hop_like(false, 1), desc = "Hop-like T" },
      }
    end,
  },
}
