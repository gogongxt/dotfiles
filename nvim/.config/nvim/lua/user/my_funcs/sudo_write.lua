local M = {}

-- 执行需要 sudo 权限的 shell 命令
-- 会先尝试无密码 sudo，如果失败再提示输入密码
M.sudo_exec = function(cmd)
  -- 1. 首先尝试无密码 sudo (-n, --non-interactive)
  -- 如果用户配置了无密码 sudo，这将直接成功，无需输入密码
  if vim.fn.system(string.format("sudo -n %s", cmd)) == 0 and vim.v.shell_error == 0 then return true end
  -- 2. 如果无密码 sudo 失败，则提示用户输入密码
  vim.fn.inputsave()
  local password = vim.fn.inputsecret "Password: "
  vim.fn.inputrestore()
  if not password or #password == 0 then
    vim.notify("未提供密码，sudo 操作已中止。", vim.log.levels.WARN)
    return false
  end
  -- 使用 -S 从标准输入读取密码, -p '' 禁止 sudo 显示自己的密码提示
  local sudo_cmd = string.format("sudo -p '' -S %s", cmd)
  local output = vim.fn.system(sudo_cmd, password)
  -- 检查命令是否执行成功
  if vim.v.shell_error ~= 0 then
    vim.notify("Sudo 命令执行失败:\n" .. output, vim.log.levels.ERROR)
    return false
  end
  return true
end

-- 使用 sudo 权限写入当前文件
M.sudo_write = function(tmpfile, filepath)
  local file_to_save = filepath or vim.fn.expand "%"
  if not file_to_save or #file_to_save == 0 then
    vim.notify("没有文件名，无法保存。", vim.log.levels.WARN)
    return
  end
  -- 1. 创建一个临时文件
  local temp_file = tmpfile or vim.fn.tempname()
  -- 2. 将当前缓冲区内容写入临时文件
  vim.api.nvim_command(string.format("write! %s", temp_file))
  -- 3. 准备 dd 命令，用于将临时文件内容复制到目标文件
  -- `bs=1048576` 等同于 `bs=1M` (GNU dd) 或 `bs=1m` (BSD dd)
  local copy_cmd =
    string.format("dd if=%s of=%s bs=1048576", vim.fn.shellescape(temp_file), vim.fn.shellescape(file_to_save))
  -- 4. 使用 sudo 执行复制命令
  if M.sudo_exec(copy_cmd) then
    vim.notify(string.format('成功使用 sudo 保存到 "%s"!', file_to_save), vim.log.levels.INFO)
    -- 5. 从磁盘重新加载文件，以同步更改并重置 'modified' 状态
    vim.cmd "e!"
    -- 6. 显式地将缓冲区设置为可写，提升用户体验
    vim.bo.readonly = false
  end
  -- 如果 M.sudo_exec 失败，它内部已经发出了错误通知
  -- 7. 确保临时文件在函数结束时被删除
  vim.fn.delete(temp_file)
end

return M
