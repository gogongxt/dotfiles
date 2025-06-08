-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "mrjones2014/smart-splits.nvim",
    -- enabled = false,
    opts = function(plugin, opts)
      -- 不希望穿越
      opts.at_edge = "stop"
      -- 交换窗口时光标跟着动
      opts.cursor_follows_swapped_bufs = true
      -- ctrl+alt+hjkl to swap window
      vim.keymap.set("n", "<c-a-h>", require("smart-splits").swap_buf_left)
      vim.keymap.set("n", "<c-a-j>", require("smart-splits").swap_buf_down)
      vim.keymap.set("n", "<c-a-k>", require("smart-splits").swap_buf_up)
      vim.keymap.set("n", "<c-a-l>", require("smart-splits").swap_buf_right)
    end,
  },
  -- {
  --   "simeji/winresizer",
  -- }
}
