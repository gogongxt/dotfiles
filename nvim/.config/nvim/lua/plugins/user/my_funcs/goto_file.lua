local M = {}

M.extract_file_info = function(string)
  local current_line
  if string then
    current_line = string
  else
    current_line = vim.api.nvim_get_current_line()
  end

  local home_directory = os.getenv "HOME"

  -- local file_path, line_num, col_num = current_line:match('(%S+):(%d+):(%d+)')
  local file_path, line_num, col_num = current_line:match "(~?$?H?O?M?E?/[^ ]+[%w]+/?):(%d+):(%d+)"
  if not (not file_path and not line_num and not col_num) then
    -- print(file_path, line_num, col_num)
    file_path = file_path:gsub("~", home_directory)
    file_path = file_path:gsub("$HOME", home_directory)
    local file = io.open(file_path, "r")
    if not file then
      -- print("[ERROR]: " .. file_path .. " not exist")
      -- return
    else
      M.go_to_file(file_path, line_num, col_num)
      return
    end
  end

  -- file_path, line_num = current_line:match('(%S+):(%d+)')
  file_path, line_num = current_line:match "(~?$?H?O?M?E?/[^ ]+[%w]+/?):(%d+)"
  if not (not file_path and not line_num) then
    -- print(file_path, line_num)
    file_path = file_path:gsub("~", home_directory)
    file_path = file_path:gsub("$HOME", home_directory)
    local file = io.open(file_path, "r")
    if not file then
      -- print("[ERROR]: " .. file_path .. " not exist")
      -- return
    else
      M.go_to_file(file_path, line_num, 0)
      return
    end
  end

  file_path = current_line:match "(~?$?H?O?M?E?/[^ ]+[%w]+/?)"
  if not not file_path then
    -- print(file_path)
    file_path = file_path:gsub("~", home_directory)
    file_path = file_path:gsub("$HOME", home_directory)
    local file = io.open(file_path, "r")
    if not file then
      -- print("[ERROR]: " .. file_path .. " not exist")
      -- return
    else
      M.go_to_file(file_path)
      return
    end
  end

  -- rust的编译报错结果是相对的 比如 src/main.rs:4:12
  -- 也就是我们要先找到git目录，再进行相对路径的搜索
  file_path, line_num, col_num = current_line:match "([^%s]+):(%d+):(%d+)"
  -- print(file_path, line_num, col_num)
  if not not file_path then
    file_path = vim.fn.getcwd() .. "/" .. file_path
    -- print(file_path)
    local file = io.open(file_path, "r")
    if not file then
      -- print("[ERROR]: " .. file_path .. " not exist")
      -- return
    else
      M.go_to_file(file_path, line_num, col_num)
      return
    end
  end

  vim.api.nvim_err_writeln "[ERROR]: cannot find the correspond file"
end

M.go_to_file = function(file, line, col)
  local buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")

  -- Check if we're in a toggleterm buffer (regular or float)
  if buf_name:match "toggleterm" or buf_type == "terminal" then
    -- Try to move to the previous window
    vim.api.nvim_command "wincmd p"

    -- If we're still in a terminal buffer, try alternative navigation
    local current_buf = vim.api.nvim_get_current_buf()
    local current_buf_name = vim.api.nvim_buf_get_name(current_buf)
    local current_buf_type = vim.api.nvim_buf_get_option(current_buf, "buftype")

    if current_buf_name:match "toggleterm" or current_buf_type == "terminal" then
      -- Fall back to navigating to the main editing area
      vim.api.nvim_command "wincmd w"
    end
  end

  -- Open the target file
  vim.api.nvim_command("edit " .. file)

  -- Navigate to the specific line and column if provided
  if line then vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) }) end
end

return M
