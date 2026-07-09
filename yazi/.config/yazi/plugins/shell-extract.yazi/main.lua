--- @since 26.5.6
--
-- Extract archives via the shell `extract` function (oh-my-zsh `extract` plugin,
-- backed up by `~/.sh_help/functions/extract.sh`).
--
-- Bound to `e` in keymap.toml as `plugin shell-extract`.
-- NOTE: named `shell-extract` (not `extract`) to avoid colliding with yazi's
-- builtin `extract` preset (yazi-plugin/preset/plugins/extract.lua), which
-- shadows local plugins of the same name and errors "No URL provided".
-- Pops up a yes/no confirm dialog before running. Operates on the current
-- selection, falling back to the hovered file.

local function info(content, level)
	return ya.notify({
		title = "Extract",
		content = content,
		timeout = 5,
		level = level,
	})
end

-- Collect selected files; fall back to the hovered file. Runs in a sync context.
local get_targets = ya.sync(function()
	local urls = {}
	for _, u in pairs(cx.active.selected) do
		urls[#urls + 1] = tostring(u)
	end
	if #urls == 0 then
		local h = cx.active.current.hovered
		if h then
			urls[#urls + 1] = tostring(h.url)
		end
	end
	return urls
end)

-- Current working directory, so `extract` writes next to the archive.
local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

return {
	-- In yazi 26.5.6 an unannotated `entry` runs in an async context already, so
	-- `ya.confirm` and `Command` can be called directly. (Wrapping in `ya.async`
	-- errors: "`ya.async()` can only be used in sync context".) `cx` state is
	-- reached via the `ya.sync` helpers above.
	entry = function()
		local targets = get_targets()
		if #targets == 0 then
			return info("No file selected", "warn")
		end

		local body
		if #targets == 1 then
			body = "Extract this file?\n\n" .. targets[1]
		else
			body = string.format("Extract these %d files?\n\n%s", #targets, table.concat(targets, "\n"))
		end

		local ok = ya.confirm({
			pos = { "center", w = 60, h = 12 },
			title = "Extract archive",
			body = body,
		})
		if not ok then
			return info("Cancelled")
		end

		-- Source ~/.zshrc so the shell `extract` function is loaded. The file
		-- list travels through YAZI_EXTRACT_FILES, not positional args: sourcing
		-- .sh_help/init.sh with a stray $1 trips its CUR_SHELL validation, so
		-- the zsh -c script must keep $@ empty while .zshrc loads. zshrc noise
		-- (p10k/gitstatus init chatter) is redirected to /dev/null.
		local script = [[
			source "$HOME/.zshrc" 2>/dev/null
			rc=0
			while IFS= read -r f; do
				[ -n "$f" ] || continue
				extract "$f" || rc=$?
			done <<< "$YAZI_EXTRACT_FILES"
			exit $rc
		]]

		local output, err = Command("zsh")
				:arg("-c")
				:arg(script)
				:cwd(get_cwd())
				:env("YAZI_EXTRACT_FILES", table.concat(targets, "\n"))
				:stdout(Command.PIPED)
				:stderr(Command.PIPED)
				:output()

		if not output then
			return info("Failed to run extract: " .. tostring(err), "error")
		end

		if output.status.success then
			info("Extracted " .. #targets .. " file(s)")
		else
			info("Extract finished with errors (code " .. tostring(output.status.code) .. ")", "warn")
		end

		-- Reload the current directory so newly extracted files appear.
		ya.emit("refresh", {})
	end,
}
