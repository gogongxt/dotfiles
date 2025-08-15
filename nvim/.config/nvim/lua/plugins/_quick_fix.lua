-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

vim.cmd [[
    hi BqfPreviewBorder guifg=#dd7878 ctermfg=71
    hi BqfPreviewTitle guifg=#ea76cb ctermfg=71
    hi BqfPreviewThumb guibg=#dd7878 ctermbg=71
    hi link BqfPreviewRange Search
]]

return {
  {
    -- better quickfix
    -- https://github.com/kevinhwang91/nvim-bqf
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    config = function()
      require("bqf").setup {
        func_map = {
          ptogglemode = "<a-s-p>",
          ptoggleauto = "<a-p>",
        },
      }
    end,
  },
}
