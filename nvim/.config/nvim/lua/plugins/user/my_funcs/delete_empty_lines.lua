local M = {}

M.delete_empty_lines = function(mode)
  local start_line, end_line, current_line, current_col
  if mode == "v" then
    -- 退出 insert 模式防止干扰
    vim.api.nvim_command "normal! "
    -- 获取可视模式的开始和结束位置
    start_line = vim.fn.line "'<"
    end_line = vim.fn.line "'>"
    -- 保存当前行号
    current_line = vim.fn.line "."
    current_col = vim.fn.col "."
  else -- 包括 mode 为 nil 或 'n' 的情况
    -- 全选文本
    start_line = 1
    end_line = vim.fn.line "$" -- 使用 line("$") 获取最后一行号
    current_line = start_line
    current_col = end_line
  end
  -- 收集需要删除的行号
  local lines_to_delete = {}
  -- 检查每一行是否为空行
  for lnum = start_line, end_line do
    local line = vim.fn.getline(lnum)
    if line:match "^%s*$" then -- 匹配只包含空白或完全为空的行
      table.insert(lines_to_delete, lnum)
    end
  end
  -- 从下往上删除行，避免行号变化影响删除
  for i = #lines_to_delete, 1, -1 do
    vim.api.nvim_buf_set_lines(0, lines_to_delete[i] - 1, lines_to_delete[i], false, {})
  end
  -- 恢复光标位置
  vim.fn.cursor(current_line, current_col)
  -- 显示删除的行数
  if #lines_to_delete > 0 then
    vim.notify("Deleted " .. #lines_to_delete .. " empty lines", vim.log.levels.INFO)
  else
    vim.notify("No empty lines found in selection", vim.log.levels.INFO)
  end
end

return M
