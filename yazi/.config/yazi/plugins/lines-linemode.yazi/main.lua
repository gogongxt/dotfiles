local M = {}

-- Maximum file size to process (2MB)
-- local MAX_FILE_SIZE = 2 * 1024 * 1024

function M:setup()
	-- Add the lines linemode function
	function Linemode:lines()
		local file = self._file

		-- Try to get size first - if nil, it's a directory
		local size = file:size()
		if not size then
			-- It's a directory, show file count
			local folder = cx.active:history(file.url)
			local count = folder and #folder.files or ""
			return tostring(count)
		end

		-- Skip files larger than 2MB
		-- if size > MAX_FILE_SIZE then
		-- 	return ""
		-- end

		local path = tostring(file.url)

		-- Directly use wc -l for all files
		-- Returns 0 for binary files (reasonable behavior)
		-- No file type or size limitations
		local handle = io.popen("wc -l " .. ya.quote(path) .. " 2>/dev/null")
		if not handle then
			return ""
		end

		local result = handle:read("*a")
		handle:close()

		-- Extract line count from "123 filename" format
		local line_count = result:match("^%s*(%d+)")
		return line_count or ""
	end
end

return M
