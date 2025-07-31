--- @since 25.5.31
--- @sync entry

-- 插件的入口函数
local function entry(_, job)
	local target_idx = tonumber(job.args[1])
	-- ya.notify({
	-- 	title = "smart-tab",
	-- 	content = "target_idx" .. target_idx,
	-- 	timeout = 5,
	-- })
	if target_idx == nil then
		ya.notify({
			title = "smart-tab",
			content = "smart-tab: 插件参数必须是一个有效的数字",
			timeout = 5,
		})
		return
	end

	-- 获取当前已打开的标签页的总数。
	local tabs_count = #cx.tabs
	-- ya.notify({
	-- 	title = "smart-tab",
	-- 	content = "tabs_count" .. tabs_count,
	-- 	timeout = 5,
	-- })

	-- 核心逻辑：
	-- 1. 如果目标索引小于当前的标签页总数，说明目标标签页已经存在，直接切换过去。
	if target_idx < tabs_count then
		-- cx.active.tabs:switch(target_idx)
		ya.emit("tab_switch", { target_idx })
		-- 2. 如果目标索引等于当前的标签页总数，说明我们想要创建一个新的、紧邻的标签页。
	elseif target_idx == tabs_count then
		-- 创建一个新的标签页。新标签页的工作目录将是当前活动标签页的工作目录。
		ya.emit("tab_create", { "" })
		-- 创建后切换到这个新标签页。
		ya.emit("tab_switch", { target_idx })
	else
		-- 不执行任何操作
	end
end

return {
	entry = entry,
}