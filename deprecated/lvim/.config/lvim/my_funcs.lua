-- my own useful functions

local M = {}

M.escape_rg_text = function(text)
  text = text:gsub('%(', '\\%(')
  text = text:gsub('%)', '\\%)')
  text = text:gsub('%[', '\\%[')
  text = text:gsub('%]', '\\%]')
  text = text:gsub('%{', '\\%{')
  text = text:gsub('%}', '\\%}')
  text = text:gsub('"', '\\"')
  text = text:gsub('-', '\\-')
  text = text:gsub('+', '\\-')

  return text
end

M.live_grep_raw = function(opts, mode)
  opts = opts or {}
  opts.prompt_title = 'Live Grep Raw (-t[ty] include, -T exclude -g"[!] [glob])"'
  -- if not opts.default_text then
  --   if mode then
  --     opts.default_text = '"' .. M.escape_rg_text(M.get_text(mode)) .. '"'
  --   else
  --     opts.default_text = '"'
  --   end
  -- end
  if mode then
    opts.default_text = opts.default_text .. '"' .. M.escape_rg_text(M.get_text(mode)) .. '"'
  end

  require('telescope').extensions.live_grep_args.live_grep_args(
  -- require('telescope.themes').get_ivy(opts)
  -- require('telescope.themes').get_cursor(opts)
    require('telescope.themes').get_dropdown(opts)
  )
end

M.get_text = function(mode)
  local current_line = vim.api.nvim_get_current_line()
  local start_pos = {}
  local end_pos = {}
  if mode == 'v' then
    start_pos = vim.api.nvim_buf_get_mark(0, "<")
    end_pos = vim.api.nvim_buf_get_mark(0, ">")
  elseif mode == 'n' then
    start_pos = vim.api.nvim_buf_get_mark(0, "[")
    end_pos = vim.api.nvim_buf_get_mark(0, "]")
  end

  return string.sub(current_line, start_pos[2] + 1, end_pos[2] + 1)
end


-- nvim0.9后废弃了range format，我们需要自己实现
-- Ref: https://www.reddit.com/r/neovim/comments/zv91wz/range_formatting/
-- nvim0.9 之前像这样使用 lvim.keys.visual_mode["<leader>lf"]   = "<ESC><cmd>lua vim.lsp.buf.range_formatting()<CR>" -- deprecated from 0.9
M.range_formatting = function()
  local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, "<"))
  local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, ">"))
  vim.lsp.buf.format({
    range = {
      ["start"] = { start_row, 0 },
      ["end"] = { end_row, 0 },
    },
    async = true,
  })
end


M.execute_and_print_cmd = function()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  local selected_text = table.concat(lines, "\n")

  if selected_text ~= '' then
    -- local command_output = vim.fn.system(selected_text)

    local command = "zsh -i -c '" .. selected_text .. "'"
    print(command)
    local handle = io.popen(command)
    local command_output = handle:read("*a")
    handle:close()

    local contents = vim.split(command_output, "\n")

    -- 检查最后一个元素是否为空字符串，如果是则删除，否则会多打印一个空行
    if contents[#contents] == '' then
      table.remove(contents, #contents)
    end

    vim.fn.setpos('.', end_pos)

    vim.api.nvim_put({ "{>>>>>>>>>>>>>>>>>>>>>>>>>>" }, 'l', true, false)
    vim.fn.setreg('+', contents) -- 将输出内容放入寄存器 +
    -- vim.cmd('normal! "+p')
    table.insert(contents, "}<<<<<<<<<<<<<<<<<<<<<<<<<<")
    vim.api.nvim_put(contents, 'l', true, false)
    -- vim.api.nvim_put({"}<<<<<<<<<<<<<<<<<<<<<<<"}, 'l', true , false)
  else
    print("no text selected")
  end
end

M.ret_null_if_input_point = function(string)
  return string == '.' and '' or string
end


M.extract_file_info = function(string)
  local current_line
  if string then
    current_line = string
  else
    current_line = vim.api.nvim_get_current_line()
  end

  local home_directory = os.getenv("HOME")

  -- local file_path, line_num, col_num = current_line:match('(%S+):(%d+):(%d+)')
  local file_path, line_num, col_num = current_line:match('(~?$?H?O?M?E?/[^ ]+[%w]+/?):(%d+):(%d+)')
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
  file_path, line_num = current_line:match('(~?$?H?O?M?E?/[^ ]+[%w]+/?):(%d+)')
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

  file_path = current_line:match('(~?$?H?O?M?E?/[^ ]+[%w]+/?)')
  if not (not file_path) then
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
  file_path, line_num, col_num = current_line:match('([^%s]+):(%d+):(%d+)')
  -- print(file_path, line_num, col_num)
  if not (not file_path) then
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

  vim.api.nvim_err_writeln("[ERROR]: cannot find the correspond file")
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
  if vim.api.nvim_buf_get_name(buf):find("toggleterm") then
    vim.api.nvim_command("wincmd w")
  end

  vim.api.nvim_command('edit ' .. file)
  if line then
    vim.api.nvim_win_set_cursor(0, { tonumber(line), tonumber(col) })
  end
end


M.DebugBuffer = function(buf)
  -- local buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local buf_type = vim.api.nvim_buf_get_option(buf, 'buftype')
  local file_type = vim.api.nvim_buf_get_option(buf, 'filetype')
  local buf_modified = vim.api.nvim_buf_get_option(buf, 'modified')
  local buf_line_count = vim.api.nvim_buf_line_count(buf)
  print("-------------------------")
  print(string.format("Buffer Name: %s", buf_name))
  print(string.format("buf Type: %s", buf_type))
  print(string.format("File Type: %s", file_type))
  print(string.format("Modified: %s", buf_modified))
  print(string.format("Line Count: %s", buf_line_count))
  print("-------------------------")
end

M.DebugAllBuffers = function()
  local buffers = vim.api.nvim_list_bufs()
  -- 遍历每个缓冲区
  for _, buf in ipairs(buffers) do
    M.DebugBuffer(buf)
  end
end


M.git_gitui_toggle = function()
  local Terminal = require("toggleterm.terminal").Terminal
  local gitui = Terminal:new {
    cmd = "gitui",
    hidden = true,
    direction = "float",
    float_opts = {
      border = "curved",
      -- width = 100000,
      -- height = 100000,
    },
    on_open = function(_)
      vim.cmd "startinsert!"
    end,
    on_close = function(_) end,
    count = 99,
  }
  gitui:toggle()
end

M.get_buf_fullpath = function()
  -- print(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
  return vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
end

M.GetBufRelativePath = function()
  local path = string.gsub(M.get_buf_fullpath(), vim.fn.getcwd(), "")
  -- Remove leading backslash if it exists
  if string.sub(path, 1, 1) == "/" then
    path = string.sub(path, 2)
  end
  -- print(path)
  return path
end

M.get_buf_name = function()
  -- print(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t"))
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
end


-- Use like ":w !sudo tee %" to save file without root
-- Ref: https://github.com/neovim/neovim/issues/12103
M.sudo_write = function(tmpfile, filepath)
  if not tmpfile then tmpfile = vim.fn.tempname() end
  if not filepath then filepath = vim.fn.expand("%") end
  if not filepath or #filepath == 0 then
    M.err("E32: No file name")
    return
  end
  -- `bs=1048576` is equivalent to `bs=1M` for GNU dd or `bs=1m` for BSD dd
  -- Both `bs=1M` and `bs=1m` are non-POSIX
  local cmd = string.format("dd if=%s of=%s bs=1048576",
    vim.fn.shellescape(tmpfile),
    vim.fn.shellescape(filepath))
  -- no need to check error as this fails the entire function
  vim.api.nvim_exec(string.format("write! %s", tmpfile), true)
  if M.sudo_exec(cmd) then
    -- vim.notify("\n\n\n", vim.log.levels.INFO, {})
    vim.notify("\n" .. string.format([["%s" write successful!]], filepath), vim.log.levels.INFO, {})
    vim.cmd("e!")
  end
  vim.fn.delete(tmpfile)
end
M.sudo_exec = function(cmd, print_output)
  vim.fn.inputsave()
  local password = vim.fn.inputsecret("Password: ")
  vim.fn.inputrestore()
  if not password or #password == 0 then
    M.warn("Invalid password, sudo aborted")
    return false
  end
  local out = vim.fn.system(string.format("sudo -p '' -S %s", cmd), password)
  if vim.v.shell_error ~= 0 then
    print("\r\n")
    M.err(out)
    return false
  end
  if print_output then print("\r\n", out) end
  return true
end

return M
