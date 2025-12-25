local M = {}

M.execute_and_print_cmd = function()
  local selected_text = vim.fn.getline "."
  local current_pos = vim.fn.getpos "."

  if selected_text ~= "" then
    local command = "zsh -i -c '" .. selected_text .. "'"
    print(command)
    local handle = io.popen(command)
    local command_output = handle:read "*a"
    handle:close()

    local contents = vim.split(command_output, "\n")

    -- 检查最后一个元素是否为空字符串，如果是则删除，否则会多打印一个空行
    if contents[#contents] == "" then table.remove(contents, #contents) end

    vim.fn.setpos(".", current_pos)

    vim.api.nvim_put({ "{==========================" }, "l", true, false)
    vim.fn.setreg("+", contents) -- 将输出内容放入寄存器 +
    table.insert(contents, "}==========================")
    vim.api.nvim_put(contents, "l", true, false)
  else
    print "no text selected"
  end
end

return M
