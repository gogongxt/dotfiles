-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local OUTLINE_NORMAL_WIDTH = 30
local OUTLINE_WIDE_WIDTH = 60

-- Toggle outline window width between normal and wide.
local function toggle_outline_width()
  local cur = vim.api.nvim_win_get_width(0)
  if cur <= OUTLINE_NORMAL_WIDTH then
    vim.api.nvim_win_set_width(0, OUTLINE_WIDE_WIDTH)
  else
    vim.api.nvim_win_set_width(0, OUTLINE_NORMAL_WIDTH)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "Outline",
  callback = function()
    vim.keymap.set("n", "e", toggle_outline_width, {
      buffer = true,
      silent = true,
      desc = "Toggle outline width",
    })
  end,
})

return {
  {
    "hedyhli/outline.nvim",
    opts = {
      outline_window = {
        position = "left",
        width = OUTLINE_NORMAL_WIDTH,
        relative_width = false,
        winhl = "Normal:NeoTreeNormal,NormalNC:NeoTreeNormalNC,CursorLine:NeoTreeCursorLine,SignColumn:NeoTreeSignColumn,EndOfBuffer:NeoTreeEndOfBuffer",
      },
    },
  },
}
