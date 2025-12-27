local M = {}

-- Cache file path
local cache_dir = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local cache_file = cache_dir .. "/yazi/lines-linemode.cache"

-- Cache table: { [path] = { mtime = number, lines = string } }
local cache = {}
local cache_max_size = 1000 -- Maximum number of cached entries
local save_counter = 0

-- Helper function to clean old cache entries
local function cleanup_cache()
	local count = 0
	for _ in pairs(cache) do
		count = count + 1
	end

	if count > cache_max_size then
		cache = {}
	end
end

-- Save cache using background shell process (non-blocking)
local function save_cache_bg()
	-- Serialize cache
	local lines = {}
	for path, data in pairs(cache) do
		table.insert(lines, string.format("[%q] = { mtime = %d, lines = %q }", path, data.mtime, data.lines))
	end
	local content = "-- Line mode cache\nreturn {\n" .. table.concat(lines, ",\n") .. "\n}"

	-- Use background process to save (non-blocking)
	local cmd = "mkdir -p "
			.. ya.quote(cache_dir .. "/yazi")
			.. " && printf "
			.. ya.quote(content)
			.. " > "
			.. ya.quote(cache_file)
	io.popen("(" .. cmd .. ") &")
end

function M:setup()
	-- Try to load cache on startup
	local f = io.open(cache_file, "r")
	if f then
		local content = f:read("*a")
		f:close()

		pcall(function()
			local loaded = load(content)()
			if type(loaded) == "table" then
				cache = loaded
			end
		end)
	end

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

		local path = tostring(file.url)

		-- Get file modification time for cache validation
		local cha = file.cha or {}
		local mtime = cha.mtime or 0

		-- Check cache first
		local cached = cache[path]
		if cached and cached.mtime == mtime then
			return cached.lines
		end

		-- Cache miss or file modified - recalculate
		local handle = io.popen("wc -l " .. ya.quote(path) .. " 2>/dev/null")
		if not handle then
			return ""
		end

		local result = handle:read("*a")
		handle:close()

		-- Extract line count from "123 filename" format
		local line_count = result:match("^%s*(%d+)")

		-- Update cache
		cleanup_cache()
		cache[path] = {
			mtime = mtime,
			lines = line_count or "",
		}

		-- Save cache every 50 updates
		save_counter = save_counter + 1
		if save_counter >= 50 then
			save_cache_bg()
			save_counter = 0
		end

		return cache[path].lines
	end
end

return M
