-- my own useful functions

local M = {}

M.escape_rg_text = function(text)
  text = text:gsub("%(", "\\%(")
  text = text:gsub("%)", "\\%)")
  text = text:gsub("%[", "\\%[")
  text = text:gsub("%]", "\\%]")
  text = text:gsub("%{", "\\%{")
  text = text:gsub("%}", "\\%}")
  text = text:gsub('"', '\\"')
  text = text:gsub("-", "\\-")
  text = text:gsub("+", "\\-")

  return text
end

M.live_grep_raw = function(opts, mode)
  opts = opts or {}
  -- --hidden表示搜索隐藏文件
  -- --no-ignore表示搜索gitignore文件
  -- --igblob表示在指定路径搜索
  opts.prompt_title = '"search_string" [--hidden] [--no-ignore] <[--iglob] (search_path)>'
  -- for normal mode
  if not opts.default_text then
    opts.default_text = '"' .. M.escape_rg_text(M.get_text(mode)) .. '"'
  else
    if opts.default_text ~= "" then opts.default_text = '"' .. opts.default_text .. '"' end
  end
  -- for visual mode
  if mode then opts.default_text = opts.default_text .. '"' .. M.escape_rg_text(M.get_text(mode)) .. '"' end

  -- default ignore files
  opts.defaults = {
    file_ignore_patterns = { ".git/", "node_modules", "build/" },
  }

  -- whether search all files
  if opts.search_all then opts.default_text = "--hidden --no-ignore " .. opts.default_text end

  local actions = require "telescope.actions"
  -- 设置快捷键
  opts.mappings = {
    i = {
      ["<C-j>"] = actions.cycle_history_next,
      ["<C-k>"] = actions.cycle_history_prev,
      ["<C-n>"] = actions.move_selection_next,
      ["<C-p>"] = actions.move_selection_previous,
    },
    n = {
      ["<C-j>"] = actions.cycle_history_next,
      ["<C-k>"] = actions.cycle_history_prev,
      ["<C-n>"] = actions.move_selection_next,
      ["<C-p>"] = actions.move_selection_previous,
    },
  }

  -- 获取vim窗口的大小
  local width = vim.o.columns
  local height = vim.o.lines
  -- require("my_sys").DEBUG("width", width)
  -- require("my_sys").DEBUG("height", height)
  -- 根据vim窗口大小选择 opts
  -- 宽度大于120默认就没有预览了，就用另一个上下预览的
  if width >= 120 then
    require("telescope").extensions.live_grep_args.live_grep_args(opts)
  else
    require("telescope").extensions.live_grep_args.live_grep_args(require("telescope.themes").get_dropdown(opts))
  end
  -- 使用一个插件实现我们自己的telescope搜索
  -- require("telescope").extensions.live_grep_args.live_grep_args(
  --   -- 使用默认主题
  --   opts
  --   -- 底下三个是telecope所自带的主题
  --   -- require('telescope.themes').get_ivy(opts)
  --   -- require('telescope.themes').get_cursor(opts)
  --   -- require("telescope.themes").get_dropdown(opts)
  -- )
end

M.get_text = function(mode)
  local current_line = vim.api.nvim_get_current_line()
  local start_pos = {}
  local end_pos = {}
  if mode == "v" then
    start_pos = vim.api.nvim_buf_get_mark(0, "<")
    end_pos = vim.api.nvim_buf_get_mark(0, ">")
  elseif mode == "n" then
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
  vim.lsp.buf.format {
    range = {
      ["start"] = { start_row, 0 },
      ["end"] = { end_row, 0 },
    },
    async = true,
  }
end

M.ret_null_if_input_point = function(string) return string == "." and "" or string end

M.DebugBuffer = function(buf)
  -- local buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(buf)
  local buf_type = vim.api.nvim_buf_get_option(buf, "buftype")
  local file_type = vim.api.nvim_buf_get_option(buf, "filetype")
  local buf_modified = vim.api.nvim_buf_get_option(buf, "modified")
  local buf_line_count = vim.api.nvim_buf_line_count(buf)
  print "-------------------------"
  print(string.format("Buffer Name: %s", buf_name))
  print(string.format("buf Type: %s", buf_type))
  print(string.format("File Type: %s", file_type))
  print(string.format("Modified: %s", buf_modified))
  print(string.format("Line Count: %s", buf_line_count))
  print "-------------------------"
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
    on_open = function(_) vim.cmd "startinsert!" end,
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
  if string.sub(path, 1, 1) == "/" then path = string.sub(path, 2) end
  -- print(path)
  return path
end

M.get_buf_name = function()
  -- print(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t"))
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
end

return M
