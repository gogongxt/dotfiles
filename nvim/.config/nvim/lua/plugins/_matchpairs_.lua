-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- 支持%跳转"<>"
vim.opt.matchpairs:append "<:>"

-- for chinese matchup
vim.o.matchpairs = vim.o.matchpairs .. ",《:》,「:」,『:』,（:）,［:］,【:】"

return {
  "gogongxt/vim-matchup",
  -- dir = "~/tmp/vim-matchup",
  init = function()
    require("match-up").setup {
      treesitter = {
        stopline = 1000,
      },
    }
  end,
}
