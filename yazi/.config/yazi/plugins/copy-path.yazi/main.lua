--- @since 25.5.0

-- 存储启动路径（在插件加载时初始化）
local startup_path = nil

-- 初始化插件，捕获启动路径
local init_plugin = ya.sync(function(state)
	-- 只在第一次调用时初始化
	if not state.startup_path then
		state.startup_path = tostring(cx.active.current.cwd)
	end
	startup_path = state.startup_path
	return state.startup_path
end)

-- 在同步上下文中获取当前文件信息（单文件，用于路径类型解析）
local get_current_file = ya.sync(function(state)
	local hovered = cx.active.current.hovered
	if not hovered then
		return nil
	end

	local path_str = tostring(hovered.url)
	local is_dir = hovered.cha.is_dir
	local basename = hovered.name:match("^(.+)%..+$") or hovered.name
	local extension = hovered.name:match("%.([^%.]+)$") or ""
	local link_to = hovered.link_to and tostring(hovered.link_to) or nil

	return {
		path_str = path_str,
		name = hovered.name,
		basename = basename,
		extension = extension,
		is_dir = is_dir,
		link_to = link_to,
	}
end)

-- 在同步上下文中收集要复制的目标：优先选中项，无选中则回退到聚焦项。
-- 与 shell-extract.yazi / diff.yazi 的约定一致。
local get_targets = ya.sync(function(state)
	local out = {}
	for _, u in pairs(cx.active.selected) do
		out[#out + 1] = tostring(u)
	end
	if #out == 0 then
		local hovered = cx.active.current.hovered
		if hovered then
			out[#out + 1] = tostring(hovered.url)
		end
	end
	return out
end)

-- 计算相对于启动路径的相对路径
local function calculate_relative_path(file_path, startup_path)
	if file_path:find(startup_path, 1, true) == 1 and #file_path > #startup_path + 1 then
		return file_path:sub(#startup_path + 2)
	elseif file_path == startup_path then
		return "."
	else
		return file_path
	end
end

-- 截断文本以适应显示
local function truncate_for_display(text, max_length)
	if #text <= max_length then
		return text
	end
	return ui.truncate(text, { max = max_length, rtl = false })
end

return {
	entry = function()
		local stored_startup_path = init_plugin()

		local targets = get_targets()
		if #targets == 0 then
			ya.notify({
				title = "Error",
				content = "No file selected",
				level = "warn",
				timeout = 3,
			})
			return
		end

		-- 单文件：沿用原有交互式菜单（路径类型含 basename/extension/symlink target）
		if #targets == 1 then
			local file_info = get_current_file()
			if not file_info then
				ya.notify({
					title = "Error",
					content = "No file selected",
					level = "warn",
					timeout = 3,
				})
				return
			end

			local relative_path = calculate_relative_path(file_info.path_str, stored_startup_path)

			-- 根据文件/文件夹类型创建选项列表，软链接时追加 Symlink target 选项
			local cands = {}

			if file_info.is_dir then
				cands = {
					{ on = "1", desc = "Full path: " .. file_info.path_str },
					{ on = "2", desc = "Folder name: " .. file_info.name },
					{ on = "3", desc = "Relative path: " .. relative_path },
				}
				if file_info.link_to then
					cands[#cands + 1] = { on = "4", desc = "Symlink target: " .. file_info.link_to }
				end
			else
				cands = {
					{ on = "1", desc = "Full path: " .. file_info.path_str },
					{ on = "2", desc = "Filename: " .. file_info.name },
					{ on = "3", desc = "Basename: " .. file_info.basename },
					{ on = "4", desc = "Extension: " .. file_info.extension },
					{ on = "5", desc = "Relative path: " .. relative_path },
				}
				if file_info.link_to then
					cands[#cands + 1] = { on = "6", desc = "Symlink target: " .. file_info.link_to }
				end
			end

			local choice = ya.which({
				cands = cands,
				silent = false,
			})

			local copied_content = ""
			local content_type = ""

			if file_info.is_dir then
				if choice == 1 then
					copied_content = file_info.path_str
					content_type = "Full path"
				elseif choice == 2 then
					copied_content = file_info.name
					content_type = "Folder name"
				elseif choice == 3 then
					copied_content = relative_path
					content_type = "Relative path"
				elseif choice == 4 and file_info.link_to then
					copied_content = file_info.link_to
					content_type = "Symlink target"
				else
					ya.notify({
						title = "Cancelled",
						content = "No selection made",
						timeout = 3,
					})
					return
				end
			else
				if choice == 1 then
					copied_content = file_info.path_str
					content_type = "Full path"
				elseif choice == 2 then
					copied_content = file_info.name
					content_type = "Filename"
				elseif choice == 3 then
					copied_content = file_info.basename
					content_type = "Basename"
				elseif choice == 4 then
					copied_content = file_info.extension
					content_type = "Extension"
				elseif choice == 5 then
					copied_content = relative_path
					content_type = "Relative path"
				elseif choice == 6 and file_info.link_to then
					copied_content = file_info.link_to
					content_type = "Symlink target"
				else
					ya.notify({
						title = "Cancelled",
						content = "No selection made",
						timeout = 3,
					})
					return
				end
			end

			ya.clipboard(copied_content)
			ya.notify({
				title = "Copied " .. content_type,
				content = truncate_for_display(copied_content, 50),
				timeout = 3,
			})
			return
		end

		-- 多文件：仅保留对多文件有意义的选项（完整路径 / 文件名 / 相对路径），
		-- 以换行分隔合并后复制到剪贴板。路径按字母序排序（cx.active.selected 的
		-- 遍历顺序不保证）。
		table.sort(targets)

		local cands = {
			{ on = "1", desc = string.format("Full paths (%d)", #targets) },
			{ on = "2", desc = string.format("Filenames (%d)", #targets) },
			{ on = "3", desc = string.format("Relative paths (%d)", #targets) },
		}

		local choice = ya.which({
			cands = cands,
			silent = false,
		})

		local copied_content = ""
		local content_type = ""

		if choice == 1 then
			copied_content = table.concat(targets, "\n")
			content_type = "Full paths"
		elseif choice == 2 then
			local names = {}
			for _, p in ipairs(targets) do
				-- 取路径最后一段作为文件名/文件夹名
				names[#names + 1] = p:match("([^/]+)$") or p
			end
			copied_content = table.concat(names, "\n")
			content_type = "Filenames"
		elseif choice == 3 then
			local rels = {}
			for _, p in ipairs(targets) do
				rels[#rels + 1] = calculate_relative_path(p, stored_startup_path)
			end
			copied_content = table.concat(rels, "\n")
			content_type = "Relative paths"
		else
			ya.notify({
				title = "Cancelled",
				content = "No selection made",
				timeout = 3,
			})
			return
		end

		ya.clipboard(copied_content)
		ya.notify({
			title = string.format("Copied %d %s", #targets, content_type),
			content = truncate_for_display(targets[1], 50) .. string.format("  (+%d more)", #targets - 1),
			timeout = 3,
		})
	end,
}
