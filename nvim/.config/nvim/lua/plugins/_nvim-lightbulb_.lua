if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    -- 在有code action的地方显示灯泡
    "kosayoda/nvim-lightbulb",
    config = function()
      require("nvim-lightbulb").setup {
        autocmd = { enabled = true },
        -- LSP client names to ignore
        -- Example: {"sumneko_lua", "null-ls"}
        ignore = {},
        sign = {
          enabled = false,
          -- Priority of the gutter sign
          priority = 10,
        },
        float = {
          enabled = false,
          -- Text to show in the popup float
          text = "💡", --
          -- Available keys for window options:
          -- - height     of floating window
          -- - width      of floating window
          -- - wrap_at    character to wrap at for computing height
          -- - max_width  maximal width of floating window
          -- - max_height maximal height of floating window
          -- - pad_left   number of columns to pad contents at left
          -- - pad_right  number of columns to pad contents at right
          -- - pad_top    number of lines to pad contents at top
          -- - pad_bottom number of lines to pad contents at bottom
          -- - offset_x   x-axis offset of the floating window
          -- - offset_y   y-axis offset of the floating window
          -- - anchor     corner of float to place at the cursor (NW, NE, SW, SE)
          -- - winblend   transparency of the window (0-100)
          win_opts = {},
        },
        virtual_text = {
          enabled = true,
          -- Text to show at virtual text
          text = "💡", --
          -- highlight mode to use for virtual text (replace, combine, blend), see :help nvim_buf_set_extmark() for reference
          hl_mode = "replace",
        },
        status_text = {
          enabled = false,
          -- Text to provide when code actions are available
          text = "💡",
          -- Text to provide when no actions are available
          text_unavailable = "",
        },
      }
    end,
  },
}
