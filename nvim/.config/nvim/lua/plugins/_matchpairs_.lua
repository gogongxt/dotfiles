-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- 支持%跳转"<>"和中文括号
vim.opt.matchpairs:append "<:>,《:》,「:」,『:』,（:）,［:］,【:】"

return {
  "gogongxt/vim-matchup",
  init = function()
    require("match-up").setup {
      treesitter = {
        stopline = 1000,
      },
    }
  end,
}
