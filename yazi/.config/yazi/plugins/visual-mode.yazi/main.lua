--- @sync entry
-- visual mode like ranger keymap
-- 如果当前不在视觉模式，则进入
-- 如果已在视觉模式，则退出

return {
  entry = function()
    -- 检查当前是否处于视觉模式
    if cx.active.mode.is_visual then
      -- 如果是，则执行 "escape" 命令退出视觉模式
      -- 使用 { visual = true } 确保只退出视觉模式，而不影响其他状态
      ya.emit("escape", { visual = true })
    else
      -- 如果不是，则执行 "visual_mode" 命令进入选择模式
      ya.emit("visual_mode", {})
    end
  end,
}
