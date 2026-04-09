-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

vim.cmd [[
    hi BqfPreviewBorder guifg=#dd7878 ctermfg=71
    hi BqfPreviewTitle guifg=#ea76cb ctermfg=71
    hi BqfPreviewThumb guibg=#dd7878 ctermbg=71
    hi link BqfPreviewRange Search
]]

-- 三状态循环：hidden -> normal -> full -> hidden
local _preview_state = {} -- per qf window state

local function cycle_preview()
  local handler = require "bqf.preview.handler"
  local qwinid = vim.api.nvim_get_current_win()

  -- 获取当前状态
  local state = _preview_state[qwinid] or "hidden"
  local next_state

  if state == "hidden" then
    next_state = "normal"
    handler.open(qwinid, nil, true)
    -- 确保不是全屏模式
    local ps = package.loaded["bqf.preview.session"] and require("bqf.preview.session"):get(qwinid)
    if ps and ps.full then handler.toggleMode(qwinid) end
  elseif state == "normal" then
    next_state = "full"
    handler.open(qwinid, nil, true)
    handler.toggleMode(qwinid)
  else -- full
    next_state = "hidden"
    handler.close(qwinid)
  end

  _preview_state[qwinid] = next_state
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
