-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- 检测当前预览状态
local function get_preview_state(qwinid)
  local pvs = require "bqf.preview.session"
  local ps = pvs:get(qwinid)
  if not ps or not ps:validate() then
    return "hidden"
  elseif ps.full then
    return "full"
  else
    return "normal"
  end
end

local function cycle_preview()
  local handler = require "bqf.preview.handler"
  local qwinid = vim.api.nvim_get_current_win()
  -- 检测当前状态
  local current_state = get_preview_state(qwinid)
  local next_state
  if current_state == "hidden" then
    next_state = "normal"
    handler.open(qwinid, nil, true)
    -- 确保不是全屏模式
    local ps = require("bqf.preview.session"):get(qwinid)
    if ps and ps.full then handler.toggleMode(qwinid) end
  elseif current_state == "normal" then
    next_state = "full"
    handler.open(qwinid, nil, true)
    handler.toggleMode(qwinid)
  else -- full
    next_state = "hidden"
    handler.close(qwinid)
  end
  vim.notify("Preview: " .. next_state, vim.log.levels.INFO)
end

-- 全屏模式
local function toggle_full()
  local handler = require "bqf.preview.handler"
  local qwinid = vim.api.nvim_get_current_win()
  handler.open(qwinid, nil, true) -- 确保预览打开
  handler.toggleMode(qwinid)
end

return {
  {
    -- better quickfix
    -- https://github.com/kevinhwang91/nvim-bqf
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    config = function()
      -- 高亮配置
      local function set_hl()
        vim.cmd [[
          hi BqfPreviewBorder guifg=#dd7878 ctermfg=71
          hi BqfPreviewTitle guifg=#ea76cb ctermfg=71
          hi BqfPreviewThumb guibg=#dd7878 ctermbg=71
          hi link BqfPreviewRange Search
        ]]
      end
      set_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

      require("bqf").setup {
        func_map = {
          ptogglemode = "", -- 禁用默认快捷键
          ptoggleauto = "", -- 禁用默认快捷键
        },
      }

      -- 手动设置快捷键
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
          vim.keymap.set("n", "<a-p>", cycle_preview, { buffer = true, desc = "Cycle preview: normal/hidden/full" })
          vim.keymap.set("n", "<a-s-p>", toggle_full, { buffer = true, desc = "Toggle preview full mode" })
        end,
      })
    end,
  },
}
