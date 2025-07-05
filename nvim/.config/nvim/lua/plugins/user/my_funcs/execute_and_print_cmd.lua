local M = {}

M.execute_and_print_cmd = function()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"

  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  local selected_text = table.concat(lines, "\n")

  if selected_text ~= "" then
    -- local command_output = vim.fn.system(selected_text)

    local command = "zsh -i -c '" .. selected_text .. "'"
    print(command)
    local handle = io.popen(command)
    local command_output = handle:read "*a"
    handle:close()

    local contents = vim.split(command_output, "\n")

    -- 检查最后一个元素是否为空字符串，如果是则删除，否则会多打印一个空行
    if contents[#contents] == "" then table.remove(contents, #contents) end

    vim.fn.setpos(".", end_pos)

    vim.api.nvim_put({ "{==========================" }, "l", true, false)
    vim.fn.setreg("+", contents) -- 将输出内容放入寄存器 +
    -- vim.cmd('normal! "+p')
    table.insert(contents, "}==========================")
    vim.api.nvim_put(contents, "l", true, false)
    -- vim.api.nvim_put({"}<<<<<<<<<<<<<<<<<<<<<<<"}, 'l', true , false)
  else
    print "no text selected"
  end
end

return M
