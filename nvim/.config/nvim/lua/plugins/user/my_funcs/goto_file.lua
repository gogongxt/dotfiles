local M = {}

-- 解析一行或多行文本中的路径/行/列
local function parse_line(text, cwd, home)
  local patterns = {
    -- 优先级 1: 匹配绝对路径、以~开头或以$HOME开头的路径
    -- $HOME 模式
    "(%$HOME/[^:%s]*):(%d+):(%d+)",
    "(%$HOME/[^:%s]*):(%d+)",
    "(%$HOME/[^:%s]*)",
    -- ~ 模式
    "([~][^:%s]*):(%d+):(%d+)",
    "([~][^:%s]*):(%d+)",
    "([~][^:%s]*)",
    -- 优先级 2: 匹配带多级目录的相对路径 (例如: src/main.rs, Projects/benchmark/...)
    "([%w%._%-]+/[^:%s]*):(%d+):(%d+)",
    "([%w%._%-]+/[^:%s]*):(%d+)",
    "([%w%._%-]+/[^:%s]*)",
    -- 优先级 3: 匹配不含路径分隔符的简单文件名 (必须包含'.')
    "([%w%._%-]+%.%w+):(%d+):(%d+)",
    "([%w%._%-]+%.%w+):(%d+)",
    "([%w%._%-]+%.%w+)",
    -- 优先级 4: / 绝对路径模式
    "([/][^:%s]*):(%d+):(%d+)",
    "([/][^:%s]*):(%d+)",
    "([/][^:%s]*)",
  }
  local file_path, line_num, col_num
  for _, pattern in ipairs(patterns) do
    file_path, line_num, col_num = text:match(pattern)
    if file_path then break end
  end
  -- print(string.format("parse %s:%s:%s", file_path, tostring(line_num), tostring(col_num)))
  if not file_path then return nil end
  -- 统一展开 ~ 和 $HOME
  if file_path:sub(1, 1) == "~" then
    -- 将 ~/path 替换为 /home/user/path
    file_path = home .. file_path:sub(2)
  elseif file_path:sub(1, 5) == "$HOME" then
    -- 将 $HOME/path 替换为 /home/user/path
    file_path = home .. file_path:sub(6)
  end
  -- 如果是相对路径，尝试拼接 cwd
  if not file_path:match "^/" then
    local test_path = cwd .. "/" .. file_path
    -- 在拼接前，可以先检查原始相对路径是否存在，以支持 ./ 和 ../
    if not vim.loop.fs_stat(file_path) and vim.loop.fs_stat(test_path) then return test_path, line_num, col_num end
  end
  return file_path, line_num, col_num
end

M.extract_file_info = function(input)
  local home = os.getenv "HOME"
  local cwd = vim.fn.getcwd()

  local function try_parse(text)
    local file, line_num, col_num = parse_line(text, cwd, home)
    -- print(string.format("parse %s:%s:%s", tostring(file), tostring(line_num), tostring(col_num)))
    if file and vim.loop.fs_stat(file) then return file, line_num, col_num end
    return nil
  end

  local current_line = input or vim.api.nvim_get_current_line()

  -- 第一步：直接解析当前行
  local file, line_num, col_num = try_parse(current_line)
  if file then
    -- print "[DEBUG] no need combined "
    M.go_to_file(file, line_num, col_num)
    return
  end

  -- 第二步：尝试多行拼接（逐步增加）
  if not input then
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum + 2, false) -- 最多取三行

    for i = 2, #lines do
      local combined = table.concat({ unpack(lines, 1, i) }, "")
      -- print("[DEBUG] combined lines -> " .. combined)
      local f2, l2, c2 = try_parse(combined)
      if f2 then
        M.go_to_file(f2, l2, c2)
        return
      end
    end
  end

  vim.api.nvim_err_writeln "[ERROR]: cannot parse file path"
end

M.go_to_file = function(file, line, col)
  if not vim.loop.fs_stat(file) then
    vim.api.nvim_err_writeln("[ERROR]: file does not exist -> " .. file)
    return
  end

  print(string.format("jump to %s:%s:%s", file, tostring(line), tostring(col)))

  local buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")

  -- 处理 toggleterm buffer
  if buf_name:match "toggleterm" or buf_type == "terminal" then
    vim.api.nvim_command "wincmd p"
    local cur_buf = vim.api.nvim_get_current_buf()
    local cur_name = vim.api.nvim_buf_get_name(cur_buf)
    local cur_type = vim.api.nvim_buf_get_option(cur_buf, "buftype")
    if cur_name:match "toggleterm" or cur_type == "terminal" then vim.api.nvim_command "wincmd w" end
  end

  vim.api.nvim_command("edit " .. vim.fn.fnameescape(file))
  if line then vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) or 0 }) end
end

return M
