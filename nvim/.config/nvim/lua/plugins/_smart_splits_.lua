-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["<C-e>"] = { "<cmd>lua require('smart-splits').start_resize_mode()<cr>", desc = "smart-splits" },
  },
}

return {
  {
    "mrjones2014/smart-splits.nvim",
    -- enabled = false,
    opts = function(_, opts)
      -- 不希望穿越
      opts.at_edge = "stop"
      -- 交换窗口时光标跟着动
      opts.cursor_follows_swapped_bufs = true
      -- 配置浮动窗口行为为mux，这样在浮动终端时可以移动到tmux窗格而不关闭浮动窗口
      opts.float_win_behavior = "mux"
      -- ctrl+alt+hjkl to swap window cannot map c-s-*
      vim.keymap.set("n", "<c-a-h>", require("smart-splits").swap_buf_left)
      vim.keymap.set("n", "<c-a-j>", require("smart-splits").swap_buf_down)
      vim.keymap.set("n", "<c-a-k>", require("smart-splits").swap_buf_up)
      vim.keymap.set("n", "<c-a-l>", require("smart-splits").swap_buf_right)
    end,
  },
}
