local M = {}

-- 下面的内容要先关闭折叠主要是因为全局操作文本会导致折叠报错
-- 所以需要临时关闭折叠
-- 再开启并且渲染treesitter
M.delete_comments = function(mode)
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()
  -- 保存并临时修改折叠设置
  local foldmethod = vim.api.nvim_win_get_option(winid, "foldmethod")
  if foldmethod == "expr" then vim.api.nvim_win_set_option(winid, "foldmethod", "manual") end
  local start_line, end_line, is_visual_mode
  if mode == "v" then
    -- 退出 insert 模式防止干扰
    vim.api.nvim_command "normal! "
    -- 获取可视模式的起止行（1-based -> 0-based）
    start_line = vim.fn.line "'<" - 1
    end_line = vim.fn.line "'>" - 1
    is_visual_mode = true
  else -- 包括 mode 为 nil 或 'n' 的情况
    -- 全选文本
    start_line = 0
    end_line = vim.api.nvim_buf_line_count(bufnr) - 1
    is_visual_mode = false
  end
  -- 是否保留 shebang
  local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
  local preserve_shebang = first_line:match "^#!"
  -- 获取 Tree-sitter parser
  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    vim.notify("No Tree-sitter parser available.", vim.log.levels.WARN)
    return
  end
  local lang = parser:lang()
  local queries = {
    python = "[(comment) (expression_statement (string))] @comment",
  }
  local default_query = "(comment) @comment"
  local query_str = queries[lang] or default_query
  local ok, query = pcall(vim.treesitter.query.parse, lang, query_str)
  if not ok or not query then
    vim.notify("Failed to parse query for " .. lang, vim.log.levels.ERROR)
    return
  end
  -- 强制重新解析以确保最新状态
  parser:parse(true)
  local tree = parser:parse()[1]
  local root = tree:root()
  local ranges_to_delete = {}
  -- 限定范围内执行（end_line+1 是因为上界是非闭区间）
  for _, node in query:iter_captures(root, bufnr, start_line, end_line + 1) do
    local node_start_row, start_col, node_end_row, end_col = node:range()
    -- 节点必须完全在选中区域内
    if node_start_row >= start_line and node_end_row <= end_line then
      if not (preserve_shebang and node_start_row == 0) then
        table.insert(ranges_to_delete, { node_start_row, start_col, node_end_row, end_col })
      end
    end
  end
  if #ranges_to_delete == 0 then
    vim.notify("No comments found" .. (is_visual_mode and " in selection" or ""), vim.log.levels.INFO)
    return
  end
  -- 逆序删除，防止位置偏移
  table.sort(ranges_to_delete, function(a, b) return a[1] > b[1] end)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  for _, range in ipairs(ranges_to_delete) do
    local start_row, start_col, end_row, end_col = unpack(range)
    local first_line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
    local last_line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
    local is_full_line = first_line:sub(1, start_col):match "^%s*$" and last_line:sub(end_col + 1):match "^%s*$"
    if is_full_line then
      vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, {})
    else
      vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, {})
    end
  end
  -- 异步恢复折叠设置和更新
  vim.schedule(function()
    -- 恢复折叠设置
    if foldmethod == "expr" then
      vim.api.nvim_win_set_option(winid, "foldmethod", "expr")
      vim.api.nvim_command "normal! zx" -- 重新计算折叠
    end
    -- 强制重新解析 Tree-sitter
    local parser = vim.treesitter.get_parser(bufnr)
    if parser then parser:parse(true) end
  end)
  vim.notify(
    "Deleted " .. #ranges_to_delete .. " comments" .. (is_visual_mode and " in selection" or ""),
    vim.log.levels.INFO
  )
end

-- 命令注册（如需在 visual 模式中使用，启用 range）
-- vim.api.nvim_create_user_command("DeleteComments", M.delete_comments, {
--   desc = "Delete comments (whole buffer in normal mode, selection in visual mode)",
--   range = true,
-- })

-- 快捷键绑定示例：
-- vim.keymap.set("n", "<Leader>ld", "<cmd>DeleteComments<CR>", { desc = "Delete Comments" })
-- vim.keymap.set("v", "<Leader>ld", "<cmd>'<,'>DeleteComments<CR>", { desc = "Delete Comments" })

return M
