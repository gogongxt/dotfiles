local M = {}

-- Check if file is likely text by reading first 512 bytes
-- Returns: true (text), false (binary), or nil (error)
local function is_text_file(path)
	local file, err = io.open(path, "rb")
	if not file then
		return nil
	end

	-- Read first 512 bytes for type detection
	local sample = file:read(512)
	file:close()

	if not sample then
		return nil
	end

	-- Check for binary indicators:
	-- - Null bytes (0x00)
	-- - Too many control characters (except \t, \n, \r)
	local null_count = 0
	local control_count = 0
	for i = 1, #sample do
		local byte = sample:byte(i)
		if byte == 0 then
			null_count = null_count + 1
		elseif byte < 9 or (byte > 13 and byte < 32) then
			-- Control characters except \t (9), \n (10), \r (13)
			control_count = control_count + 1
		end
	end

	-- If we find null bytes or too many control chars, it's binary
	if null_count > 0 or control_count > 10 then
		return false
	end

	return true
end

-- Count lines in a file using Lua I/O
-- Returns line count or nil on error
local function count_lines(path)
	local file, err = io.open(path, "rb")
	if not file then
		return nil
	end

	local count = 0
	local chunk_size = 8192 -- Read in 8KB chunks

	while true do
		local chunk = file:read(chunk_size)
		if not chunk then
			break
		end

		-- Count newlines in this chunk
		for _ in chunk:gmatch("\n") do
			count = count + 1
		end
	end

	file:close()
	return count
end

function M:setup()
	function Linemode:lines()
		local file = self._file

		-- Handle directories - show file count
		local size = file:size()
		if not size then
			local folder = cx.active:history(file.url)
			local count = folder and #folder.files or ""
			return tostring(count)
		end

		local path = tostring(file.url)

		-- Quick check: is this a text file?
		local is_text = is_text_file(path)

		-- If can't determine or is binary, return empty
		if is_text == nil or is_text == false then
			return ""
		end

		-- Count lines using Lua I/O (no external commands)
		local line_count = count_lines(path)
		if line_count == nil then
			return ""
		end

		return tostring(line_count)
	end
end

return M
