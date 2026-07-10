local M = {}

--- 在选中行的每一行之间插入空白行（如果两行之间没有空白行）
--- @param mode string|nil "v" 表示 visual 模式，nil 或 "n" 表示 normal 模式（全缓冲区）
M.insert_blank_lines = function(mode)
  local start_line, end_line
  if mode == "v" then
    -- 退出 insert 模式防止干扰
    vim.api.nvim_command "normal! \27"
    -- 获取可视模式的起止行（1-based）
    start_line = vim.fn.line "'<"
    end_line = vim.fn.line "'>"
  else -- 包括 mode 为 nil 或 'n' 的情况
    start_line = 1
    end_line = vim.fn.line "$"
  end

  -- 收集需要插入空行的位置（在哪个行号之后插入）
  local insert_positions = {}

  -- 检查相邻两行之间是否有空行，从下往上遍历避免行号偏移问题
  for lnum = end_line - 1, start_line, -1 do
    local current_line = vim.fn.getline(lnum)
    local next_line = vim.fn.getline(lnum + 1)
    -- 当前行不是空行且下一行不是空行，才需要插入空行
    if not current_line:match "^%s*$" and not next_line:match "^%s*$" then table.insert(insert_positions, lnum) end
  end

  if #insert_positions == 0 then
    vim.notify("No blank lines need to be inserted", vim.log.levels.INFO)
    return
  end

  -- 从下往上插入空行，避免行号变化影响
  for _, pos in ipairs(insert_positions) do
    vim.api.nvim_buf_set_lines(0, pos, pos, false, { "" })
  end

  vim.notify("Inserted " .. #insert_positions .. " blank lines", vim.log.levels.INFO)
end

return M
