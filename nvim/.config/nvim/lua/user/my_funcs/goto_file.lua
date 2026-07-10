local M = {}

-- 解析一行或多行文本中的路径/行/列
M.parse_line = function(text, cwd, home)
  local patterns = {
    -- 特例优先安排
    -- 给ipython使用，匹配 "File /path/to/file:line, in" 格式
    -- File /nfs/ofs-llm-ssd/user/gogongxt/Projects/nano-sglang/nanosglang/model_executor/model_runner.py:250, in __init__
    "File%s+(/[^:%s]*):(%d+),",

    -- 优先级 1: 匹配绝对路径、以~开头或以$HOME开头的路径
    -- $HOME 模式
    "(%$HOME/[^:%s]*):(%d+):(%d+)",
    "(%$HOME/[^:%s]*):(%d+)",
    "(%$HOME/[^:%s]*)",
    -- ~ 模式
    "([~][^:%s]*):(%d+):(%d+)",
    "([~][^:%s]*):(%d+)",
    "([~][^:%s]*)",
    -- / 绝对路径模式 (只匹配以 / 开头的完整路径)
    "^([/][^:%s]*):(%d+):(%d+)",
    "^([/][^:%s]*):(%d+)",
    "^([/][^:%s]*)",
    -- 优先级 2: 匹配带多级目录的相对路径 (例如: src/main.rs, Projects/benchmark/...)
    "([%w%._%-]+/[^:%s]*):(%d+):(%d+)",
    "([%w%._%-]+/[^:%s]*):(%d+)",
    "([%w%._%-]+/[^:%s]*)",
    -- 优先级 3: 匹配不含路径分隔符的简单文件名 (必须包含'.')
    "([%w%._%-]+%.%w+):(%d+):(%d+)",
    "([%w%._%-]+%.%w+):(%d+)",
    "([%w%._%-]+%.%w+)",
  }
  local file_path, line_num, col_num
  for _, pattern in ipairs(patterns) do
    file_path, line_num, col_num = text:match(pattern)
    if file_path then
      -- print("Matched pattern: " .. pattern)
      -- print("Captured file_path: " .. file_path)
      break
    end
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
    local file, line_num, col_num = M.parse_line(text, cwd, home)
    -- print(string.format("parse %s:%s:%s", tostring(file), tostring(line_num), tostring(col_num)))
    if file and vim.loop.fs_stat(file) then return file, line_num, col_num end
    return nil
  end

  -- 如果有输入参数，直接解析输入的文本
  if input then
    local file, line_num, col_num = try_parse(input)
    if file then
      M.go_to_file(file, line_num, col_num)
      return
    end
    vim.api.nvim_err_writeln "[ERROR]: cannot parse file path"
    return
  end

  -- 获取光标位置
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local col_num = cursor[2]
  local line_text = vim.api.nvim_get_current_line()

  -- 从光标位置向左右扩展寻找文件路径
  local function find_path_at_cursor()
    local left = col_num
    local right = col_num

    -- 向左扩展，直到遇到不可能是文件路径字符的位置
    while left > 0 do
      local char = line_text:sub(left, left)
      -- 文件路径可以包含的字符：字母、数字、点、下划线、斜杠、反斜杠、$、~、-、+、冒号
      if char:match("[%w%._%/\\$~%-%+:]") then
        left = left - 1
      else
        break
      end
    end

    -- 向右扩展，直到遇到不可能是文件路径字符的位置
    while right < #line_text do
      local char = line_text:sub(right + 1, right + 1)
      if char:match("[%w%._%/\\$~%-%+:]") then
        right = right + 1
      else
        break
      end
    end

    -- 提取可能包含文件路径的文本
    local candidate = line_text:sub(left + 1, right + 1)
    return candidate
  end

  -- 获取光标位置的候选文本
  local candidate_text = find_path_at_cursor()

  -- 尝试解析候选文本
  local file, line_num_from_path, col_num_from_path = try_parse(candidate_text)
  if file then
    M.go_to_file(file, line_num_from_path, col_num_from_path)
    return
  end

  -- 如果没有找到，尝试扩大搜索范围，包括前后词
  local function get_extended_candidate()
    local words = {}
    for word in line_text:gmatch("[%w%._%/\\$~%-%+:]+") do
      table.insert(words, word)
    end

    -- 找到包含光标位置的词
    local pos = 0
    for i, word in ipairs(words) do
      local word_start = line_text:find(word, pos, true)
      local word_end = word_start + #word - 1
      if col_num >= word_start - 1 and col_num <= word_end - 1 then
        return word
      end
      pos = word_end + 1
    end
    return nil
  end

  local extended_candidate = get_extended_candidate()
  if extended_candidate then
    local file, line_num_from_path, col_num_from_path = try_parse(extended_candidate)
    if file then
      M.go_to_file(file, line_num_from_path, col_num_from_path)
      return
    end
  end

  -- 第三步：尝试多行拼接，专门处理编译错误等跨行情况
  local function try_multi_line_concat()
    local bufnr = vim.api.nvim_get_current_buf()
    local total_lines = vim.api.nvim_buf_line_count(bufnr)

    -- 首先检查光标周围的上下文，看是否有路径特征
    local has_path_chars = line_text:match("[/\\]") or line_text:match("%.%w") or line_text:match("%.cc") or line_text:match("%.cpp") or line_text:match("%.py") or line_text:match("%.js")

    -- 如果当前行有路径特征，或者在行首/行末，尝试多行拼接
    local should_try_concat = (
      has_path_chars or
      col_num <= 10 or  -- 行首10个字符内
      col_num >= #line_text - 10  -- 行末10个字符内
    )

    if should_try_concat then
      -- 尝试所有可能的多行组合（向上和向下各最多3行）
      local context_start = math.max(1, line_num - 3)
      local context_end = math.min(total_lines, line_num + 3)
      local context_lines = vim.api.nvim_buf_get_lines(bufnr, context_start - 1, context_end, false)

      -- 生成当前行在上下文中的索引
      local current_line_index = line_num - context_start + 1

      -- 尝试从当前行开始的各种组合
      -- 1. 先尝试只拼接相邻行
      local combinations = {
        -- 只向下拼接
        {current_line_index, current_line_index + 1},
        {current_line_index, current_line_index + 1, current_line_index + 2},
        -- 只向上拼接
        {current_line_index - 1, current_line_index},
        {current_line_index - 2, current_line_index - 1, current_line_index},
        -- 上下都拼接
        {current_line_index - 1, current_line_index, current_line_index + 1},
        {current_line_index - 2, current_line_index - 1, current_line_index, current_line_index + 1},
      }

      -- 先尝试包含光标的小范围组合
      for _, combo in ipairs(combinations) do
        local valid_combo = true
        for _, idx in ipairs(combo) do
          if idx < 1 or idx > #context_lines then
            valid_combo = false
            break
          end
        end

        if valid_combo then
          local combined = ""
          for _, idx in ipairs(combo) do
            combined = combined .. context_lines[idx]
          end

          -- 移除换行符和多余空白
          combined = combined:gsub("%s+", "")

          local file, l, c = try_parse(combined)
          if file then
            print(string.format("[DEBUG] Found file in multi-line: %s -> %s:%s:%s", combined, file, tostring(l), tostring(c)))
            M.go_to_file(file, l, c)
            return true
          end
        end
      end

      -- 如果还没找到，尝试整个上下文
      local full_context = table.concat(context_lines, ""):gsub("%s+", "")
      print("[DEBUG] Trying full context: " .. full_context)
      local file, l, c = try_parse(full_context)
      if file then
        print(string.format("[DEBUG] Found file in full context: %s:%s:%s", file, tostring(l), tostring(c)))
        M.go_to_file(file, l, c)
        return true
      end
    end

    -- 特殊情况：如果当前行包含 :行号:列号 模式，特别处理
    if line_text:match(":%d+:%d+") then
      -- 这是编译错误的行号部分，向上查找文件名
      for i = 1, math.min(5, line_num - 1) do
        local lines_to_check = {}
        for j = i, 1, -1 do
          table.insert(lines_to_check, vim.api.nvim_buf_get_lines(bufnr, line_num - j - 1, line_num - j, false)[1] or "")
        end
        table.insert(lines_to_check, line_text)

        local combined = table.concat(lines_to_check, ""):gsub("%s+", "")
        local file, l, c = try_parse(combined)
        if file then
          M.go_to_file(file, l, c)
          return true
        end
      end
    end

    return false
  end

  if try_multi_line_concat() then
    return
  end

  vim.api.nvim_err_writeln "[ERROR]: cannot parse file path at cursor position"
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
