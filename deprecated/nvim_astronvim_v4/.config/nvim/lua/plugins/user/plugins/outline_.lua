-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "hedyhli/outline.nvim",
    event = "VeryLazy",
    config = function() require("outline").setup {} end,
  },
  {
    "liuchengxu/vista.vim",
    event = "VeryLazy",
  },
}
