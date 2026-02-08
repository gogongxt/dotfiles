local M = {}

-- 用于存储待注册的 which-key 映射
---@type table?
M.which_key_queue = nil

-- 设置快捷键映射
---@param map_table table 嵌套表，第一层键是模式，第二层键是快捷键，值是映射配置
---@param base? table 所有映射共享的基础配置
function M.set_mappings(map_table, base)
  local was_no_which_key_queue = not M.which_key_queue

  -- 设置默认选项：noremap = true, silent = true
  local default_opts = {
    noremap = true,
    silent = true,
  }

  -- 合并用户提供的基础选项（如果有）
  local base_opts = vim.tbl_deep_extend("force", default_opts, base or {})

  for mode, maps in pairs(map_table) do
    for keymap, options in pairs(maps) do
      if options == false then
        -- 删除映射
        pcall(vim.keymap.del, mode, keymap)
      elseif options then
        local cmd
        local keymap_opts = vim.deepcopy(base_opts) -- 复制基础选项

        if type(options) == "string" or type(options) == "function" then
          cmd = options
        else
          cmd = options[1]
          -- 合并选项，允许特定映射覆盖默认值
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, options)
          keymap_opts[1] = nil
        end

        if not cmd then -- which-key 映射，加入队列
          keymap_opts[1], keymap_opts.mode = keymap, mode
          if not keymap_opts.group then keymap_opts.group = keymap_opts.desc end
          if not M.which_key_queue then M.which_key_queue = {} end
          table.insert(M.which_key_queue, keymap_opts)
        else -- 普通映射，直接设置
          vim.keymap.set(mode, keymap, cmd, keymap_opts)
        end
      end
    end
  end

  if was_no_which_key_queue and M.which_key_queue then
    require("which-key").register(M.which_key_queue)
    M.which_key_queue = nil
  end
end

return M
