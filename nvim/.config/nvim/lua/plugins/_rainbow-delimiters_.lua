-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "HiPhish/rainbow-delimiters.nvim",
  config = function()
    require("rainbow-delimiters.setup").setup {
      highlight = {
        "RainbowDelimiterBlue",
        "RainbowDelimiterViolet",
        "RainbowDelimiterRed",
        "RainbowDelimiterYellow",
        "RainbowDelimiterGreen",
        "RainbowDelimiterOrange",
        "RainbowDelimiterCyan",
      },
    }
  end,
}
