-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local function jump_to_buffer_by_number(num)
  local bufs = vim.tbl_filter(require("astrocore.buffer").is_valid, vim.t.bufs or {})
  if num > 0 and num <= #bufs then
    vim.api.nvim_win_set_buf(0, bufs[num])
  else
    vim.notify("Buffer number " .. num .. " out of range", vim.log.levels.WARN)
  end
end

for i = 1, 9 do
  vim.keymap.set("n", "<Leader>b" .. i, function() jump_to_buffer_by_number(i) end)
end

return {}