-- my own useful functions

local M = {}

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

M.GetBufRelativePath = function() return vim.fn.expand "%:p:." end

return M
