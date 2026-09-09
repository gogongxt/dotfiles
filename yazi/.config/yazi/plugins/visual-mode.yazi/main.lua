--- @sync entry
-- visual mode like ranger keymap
-- 如果当前不在视觉模式，则进入
-- 如果已在视觉模式，则退出

return {
  entry = function()
    -- 检查当前是否处于普通模式（is_visual 已在 v26.8.15 废弃，改用 is_normal）
    if cx.active.mode.is_normal then
      -- 普通模式 -> 执行 "visual_mode" 命令进入选择模式
      ya.emit("visual_mode", {})
    else
      -- 视觉模式 -> 执行 "escape" 命令退出视觉模式
      -- 使用 { visual = true } 确保只退出视觉模式，而不影响其他状态
      ya.emit("escape", { visual = true })
    end
  end,
}
