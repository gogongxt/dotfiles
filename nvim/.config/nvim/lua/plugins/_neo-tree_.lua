-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- vim.keymap.set("n", "<leader>E", "<cmd>Neotree reveal<CR>", { desc = "Toggle Neo-tree & Reveal File" })

local enable_smart_autofollow = true

if enable_smart_autofollow then
  local project_root = vim.fn.getcwd()
  local group = vim.api.nvim_create_augroup("NeoTreeSmartFollow", { clear = true })
  local is_switching_from_neo_tree = false
  -- 检测从 Neo-tree 切换出来的事件
  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    callback = function()
      if vim.bo.filetype == "neo-tree" then
        is_switching_from_neo_tree = true
        -- 设置一个短暂的超时后重置标志
        vim.defer_fn(function() is_switching_from_neo_tree = false end, 50)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      -- 如果是从 Neo-tree 切换出来的，跳过自动跟随
      if is_switching_from_neo_tree then
        -- print "跳过：从 Neo-tree 切换出来"
        return
      end
      -- 1. 基础过滤
      -- print "=== BufEnter 事件触发 ==="
      -- print("filetype:", vim.bo.filetype)
      -- print("buftype:", vim.bo.buftype)
      if vim.bo.filetype == "neo-tree" or vim.bo.buftype ~= "" then
        -- print "跳过：neo-tree 或特殊 buffer"
        return
      end
      local bufpath = vim.api.nvim_buf_get_name(0)
      -- print("buffer path:", bufpath)
      if bufpath == "" or vim.fn.filereadable(bufpath) == 0 then
        -- print "跳过：空路径或不可读文件"
        return
      end
      -- 2. 检查 Neo-tree 是否真的打开（延迟检查以确保窗口状态已更新）
      vim.defer_fn(function()
        -- 重新检查所有窗口，确保 Neo-tree 确实存在
        local neo_tree_windows = {}
        for _, winid in ipairs(vim.api.nvim_list_wins()) do
          local buf = vim.api.nvim_win_get_buf(winid)
          local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
          if filetype == "neo-tree" then table.insert(neo_tree_windows, winid) end
        end
        if #neo_tree_windows == 0 then
          -- print "跳过：neo-tree 未打开"
          return
        end
        -- 3. 使用官方方法获取当前 Neo-tree 窗口的状态
        local manager = require "neo-tree.sources.manager"
        local current_source
        for _, winid in ipairs(neo_tree_windows) do
          local state = manager.get_state_for_window(winid)
          if state then
            current_source = state.name
            -- print("找到 Neo-tree 窗口:", winid, "source:", current_source)
            break
          end
        end
        if not current_source then
          -- print "无法确定 Neo-tree 的 source"
          return
        end
        -- print("当前活跃 source:", current_source)
        -- 4. 只在 filesystem 页面才进行自动跟随
        if current_source ~= "filesystem" then
          -- print "跳过：当前不在 filesystem 页面"
          return
        end
        -- print "执行自动跟随..."
        local is_inside = vim.startswith(bufpath, project_root)
        -- print("文件在项目内:", is_inside)
        -- print("项目根目录:", project_root)
        require("neo-tree.command").execute {
          action = "show",
          source = "filesystem",
          dir = is_inside and project_root or nil,
          reveal_force_cwd = not is_inside,
        }
        -- print "自动跟随完成"
      end, 20) -- 延迟 20ms 确保窗口状态已更新
    end,
  })
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    opts.window = {
      width = 30,
      mappings = {
        ["<S-CR>"] = "system_open",
        y = "copy_to_clipboard", -- disable space until we figure out which-key disabling
        -- ["<S-h>"] = "prev_source",
        -- ["<S-l>"] = "next_source",
        ["<a-p>"] = {
          "toggle_preview",
          config = {
            use_float = true,
            use_snacks_image = true,
            use_image_nvim = true,
          },
        },
        -- P = false,
        p = "paste_from_clipboard",
        o = "system_open",
        Y = "copy_selector",
        h = "parent_or_close",
        l = "child_or_open",
        H = "prev_source",
        L = "next_source",
        ["<c-\\>"] = "open_vsplit",
        ["<c-_>"] = "open_split",
      },
      fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
        ["<C-J>"] = "move_cursor_down",
        ["<C-K>"] = "move_cursor_up",
      },
    }
    opts.filesystem = {
      use_libuv_file_watcher = true, -- use the OS level file watchers to detect changes
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      hijack_netrw_behavior = "open_current",
      filtered_items = {
        -- set always show hidden file
        visible = true,
      },
      window = {
        mappings = {
          ["<a-h>"] = "toggle_hidden",
        },
      },
    }
    return opts
  end,
}
