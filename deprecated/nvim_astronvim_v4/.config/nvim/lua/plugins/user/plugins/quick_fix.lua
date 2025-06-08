-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    -- 构建任务系统
    -- https://github.com/skywind3000/asynctasks.vim/blob/master/README-cn.md
    "skywind3000/asynctasks.vim",
    config = function()
    end
  },
  {
    -- 构建任务系统
    "skywind3000/asyncrun.vim",
    config = function()
    end
  },
  {
    -- better quickfix
    -- https://github.com/kevinhwang91/nvim-bqf
    "kevinhwang91/nvim-bqf",
    ft = 'qf',
    config = function()
      -- require("bqf").setup({
      -- })
    end,
  },
}
