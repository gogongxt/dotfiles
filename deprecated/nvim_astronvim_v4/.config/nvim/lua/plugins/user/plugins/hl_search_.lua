-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    -- 增强/高亮搜索（在右侧显示检测到多少个，当前在第几个）
    "kevinhwang91/nvim-hlslens",
    event = "VeryLazy",
    config = function()
      require('hlslens').setup({
        calm_down = false,
        nearest_only = true,
        nearest_float_when = 'never',
        override_lens = function(render, posList, nearest, idx, relIdx)
          local lnum, col = unpack(posList[idx])
          local cnt = #posList
          local text = ('[%d/%d]'):format(idx, cnt)
          local chunks = { { ' ' }, { text, 'HlSearchLensNear' } }
          render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
        end
      })
      local kopts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap('n', 'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
    end
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = function(_, opts)
      opts.messages = {
        enabled = true,            -- enables the Noice messages UI
        view = "notify",           -- default view for messages
        view_error = "notify",     -- view for errors
        view_warn = "notify",      -- view for warnings
        view_history = "messages", -- view for :messages
        view_search = false,       -- view for search count messages. Set to `false` to disable
      }
    end,

  }
}
