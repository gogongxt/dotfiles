local M = {}

-- Options, override via :setup({ size_limit = ..., parallel = ..., batch = ... })
local opts = {
	size_limit = 128 * 1024 * 1024, -- Skip line counting for files larger than this (bytes)
	parallel = 8, -- Concurrent `wc -l` processes
	batch = 200, -- Max files fed to a single `wc` round (argv length safety)
}

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

-- Human-readable size, e.g. 2.4G
local function human_size(n)
	local units = { "B", "K", "M", "G", "T" }
	local i = 1
	while n >= 1024 and i < #units do
		n = n / 1024
		i = i + 1
	end
	if i == 1 then
		return string.format("%d%s", n, units[1])
	end
	return string.format("%.1f%s", n, units[i])
end

-- Publish counting results in the main thread: update cache and refresh the UI.
-- The linemode function below only reads this cache, so counting never blocks rendering.
local publish = ya.sync(function(_, results, mtimes)
	cleanup_cache()
	for path, lines in pairs(results) do
		cache[path] = { mtime = mtimes[path] or 0, lines = lines }
	end

	-- Save cache every 50 updates
	save_counter = save_counter + 1
	if save_counter >= 50 then
		save_cache_bg()
		save_counter = 0
	end

	ui.render()
end)

-- Only count when some tab actually displays the `lines` linemode, so browsing with
-- other linemodes spawns no `wc` tasks at all (and quitting is never held up by them)
local wants_lines = ya.sync(function()
	for _, tab in ipairs(cx.tabs) do
		local pref = tab.pref
		if pref and pref.linemode == "lines" then
			return true
		end
	end
	return false
end)

-- Whether the current folder still has files without a valid cached line count
local has_misses = ya.sync(function()
	local files = cx.active.current.files
	for i = 1, #files do
		local f = files[i]
		local cha = f.cha or {}
		if not cha.is_dir and not cha.is_link and cha.len and cha.len <= opts.size_limit then
			local cached = cache[tostring(f.url)]
			if not (cached and cached.mtime == cha.mtime) then
				return true
			end
		end
	end
	return false
end)

function M.setup(_, o)
	for k, v in pairs(o or {}) do
		opts[k] = v
	end

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

		-- Oversized files: skip counting, show the size instead
		if size > opts.size_limit then
			return "≥" .. human_size(size)
		end

		local path = tostring(file.url)
		local cached = cache[path]
		local mtime = file.cha and file.cha.mtime or 0
		if cached and cached.mtime == mtime then
			return cached.lines
		end

		-- Not counted yet, leave it empty for now;
		-- the fetcher below counts it in the background and refreshes the UI
		return ""
	end
end

-- `ml` entry: switch to the `lines` linemode, and re-trigger the fetchers since folders
-- loaded while another linemode was active were skipped by the `wants_lines` gate
function M.entry()
	ya.emit("linemode", { "lines" })
	if has_misses() then
		ya.emit("refresh", {})
	end
end

-- Report every file back to yazi with `retry = true`, keeping them eligible for
-- re-fetching: modified files get recounted automatically, and folders loaded while no
-- tab displays the `lines` linemode are counted once `ml` is pressed
local function report(job)
	return ya.co(function()
		for _, file in ipairs(job.files) do
			coroutine.yield(file, { retry = true })
		end
	end)
end

-- Count lines in background fetcher tasks (see [[plugin.prepend_fetchers]] in yazi.toml),
-- so the UI is never blocked no matter how large/slow the files are.
local function fetch(_, job)
	-- Bail out immediately when no tab displays line counts. Nothing is counted and the
	-- task finishes at once, but the files stay eligible for a re-run once `ml` is pressed.
	if not wants_lines() then
		return report(job)
	end

	local todo, mtimes = {}, {}
	for _, f in ipairs(job.files) do
		local cha = f.cha or {}
		-- Only regular files within the size limit: skip dirs, symlinks (their cha.len is
		-- the length of the link path, so the target could be huge) and oversized files
		if not cha.is_dir and not cha.is_link and cha.len and cha.len <= opts.size_limit then
			local path = tostring(f.url)
			local cached = cache[path]
			if not (cached and cached.mtime == cha.mtime) then
				todo[#todo + 1] = path
				mtimes[path] = cha.mtime or 0
			end
		end
	end

	if #todo == 0 then
		return report(job)
	end

	-- Count a batch of files in parallel: one `wc -l` process per file, up to `parallel` at a time
	local script = [[printf '%s\0' "$@" | xargs -0 -n1 -P]] .. tostring(opts.parallel) .. [[ wc -l]]

	for i = 1, #todo, opts.batch do
		local chunk = {}
		for j = i, math.min(i + opts.batch - 1, #todo) do
			chunk[#chunk + 1] = todo[j]
		end

		local output, err = Command("sh")
			:arg({ "-c", script, "sh" })
			:arg(chunk)
			:stderr(Command.NULL)
			:output()
		if not output then
			ya.err("lines-linemode: cannot spawn `wc` command, error: " .. err)
			return report(job)
		end

		-- Parse "<count> <path>" lines, only accept paths we asked for
		local results = {}
		for line in output.stdout:gmatch("[^\r\n]+") do
			local n, p = line:match("^(%d+)%s+(.+)$")
			if n and mtimes[p] then
				results[p] = n
			end
		end
		-- Cache misses as empty strings, so failed files are not retried on every fetch
		for _, p in ipairs(chunk) do
			results[p] = results[p] or ""
		end

		publish(results, mtimes)
	end

	return report(job)
end

return { setup = M.setup, entry = M.entry, fetch = fetch }
