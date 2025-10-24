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

-- 在同步上下文中获取当前文件信息
local get_current_file = ya.sync(function(state)
	local hovered = cx.active.current.hovered
	if not hovered then
		return nil
	end

	local path_str = tostring(hovered.url)
	local is_dir = hovered.cha.is_dir
	local basename = hovered.name:match("^(.+)%..+$") or hovered.name
	local extension = hovered.name:match("%.([^%.]+)$") or ""

	return {
		path_str = path_str,
		name = hovered.name,
		basename = basename,
		extension = extension,
		is_dir = is_dir,
	}
end)

-- 计算相对于启动路径的相对路径
local function calculate_relative_path(file_path, startup_path)
	if file_path:find(startup_path, 1, true) == 1 and #file_path > #startup_path + 1 then
		-- 如果file_path以startup_path开头，并且后面还有内容
		return file_path:sub(#startup_path + 2) -- 跳过 startup_path + "/"
	elseif file_path == startup_path then
		-- 如果file_path就是startup_path本身
		return "."
	else
		-- 如果不在startup_path下，直接使用完整路径作为相对路径
		return file_path
	end
end

-- 截断文本以适应显示
local function truncate_for_display(text, max_length)
	if #text <= max_length then
		return text
	end
	return ya.truncate(text, { max = max_length, rtl = false })
end

return {
	entry = function()
		-- 首先初始化启动路径
		local stored_startup_path = init_plugin()

		-- 使用 sync 函数获取当前文件信息
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

		-- 计算相对于启动路径的相对路径
		local relative_path = calculate_relative_path(file_info.path_str, stored_startup_path)

		-- 调试信息（已注释）
		-- ya.notify({
		-- 	title = "Debug Info",
		-- 	content = "Path: "
		-- 			.. file_info.path_str
		-- 			.. "\nStartup: "
		-- 			.. stored_startup_path
		-- 			.. "\nRelative: "
		-- 			.. relative_path,
		-- 	timeout = 5,
		-- 	level = "info",
		-- })

		-- 根据文件/文件夹类型创建不同的选项列表
		local cands = {}

		if file_info.is_dir then
			-- 文件夹选项：完整路径、文件夹名、相对路径
			cands = {
				{ on = "1", desc = "Full path: " .. file_info.path_str },
				{ on = "2", desc = "Folder name: " .. file_info.name },
				{ on = "3", desc = "Relative path: " .. relative_path },
			}
		else
			-- 文件选项：完整路径、文件名、基础名、扩展名、相对路径
			cands = {
				{ on = "1", desc = "Full path: " .. file_info.path_str },
				{ on = "2", desc = "Filename: " .. file_info.name },
				{ on = "3", desc = "Basename: " .. file_info.basename },
				{ on = "4", desc = "Extension: " .. file_info.extension },
				{ on = "5", desc = "Relative path: " .. relative_path },
			}
		end

		local choice = ya.which({
			cands = cands,
			silent = false,
		})

		local copied_content = ""
		local content_type = ""

		if file_info.is_dir then
			-- 文件夹选项处理
			if choice == 1 then
				copied_content = file_info.path_str
				content_type = "Full path"
			elseif choice == 2 then
				copied_content = file_info.name
				content_type = "Folder name"
			elseif choice == 3 then
				copied_content = relative_path -- 使用计算出的相对路径
				content_type = "Relative path"
			else
				ya.notify({
					title = "Cancelled",
					content = "No selection made",
					timeout = 3,
				})
				return
			end
		else
			-- 文件选项处理
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
				copied_content = relative_path -- 使用计算出的相对路径
				content_type = "Relative path"
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
	end,
}
