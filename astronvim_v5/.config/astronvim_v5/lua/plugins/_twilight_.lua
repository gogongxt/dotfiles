if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  -- 只高亮光标所在代码块
  "folke/twilight.nvim",
  opts = {
    -- context = 3,
    -- use treesitter when available for the filetype
    treesitter = true,
  },
}
