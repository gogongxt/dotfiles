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
  -- 需要根据是否是终端而进行区分，如果在终端就需要先回到主窗口
  -- if (cur_file_type == "toggleterm") then
  --   vim.api.nvim_command(":ToggleTerm")
  -- end
  -- toggleterm#101 是浮动终端
  -- print(vim.api.nvim_buf_get_name(cur_buf))
  -- if vim.api.nvim_buf_get_name(cur_buf):find("toggleterm#101") then
  --   vim.api.nvim_command(":ToggleTerm")
  -- end
  if vim.api.nvim_buf_get_name(buf):find "toggleterm" then vim.api.nvim_command "wincmd w" end

  -- 如果是从":term"执行的输出，buffertype就是terminal
  if vim.api.nvim_buf_get_option(buf, "buftype"):find "terminal" then vim.api.nvim_command "wincmd w" end

  vim.api.nvim_command("edit " .. file)
  if line then vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) }) end
end

return M
