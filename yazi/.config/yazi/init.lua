-- Show symlink in status bar : https://yazi-rs.github.io/docs/tips#symlink-in-status
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

-- Show user/group of files in status bar : https://yazi-rs.github.io/docs/tips#user-group-in-status
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	})
end, 500, Status.RIGHT)

-- Full border : https://github.com/yazi-rs/plugins/tree/main/full-border.yazi
-- require("full-border"):setup({
-- 	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
-- 	type = ui.Border.ROUNDED,
-- })

-- yazi git plugin
require("git"):setup()

-- yazi starship plugin
require("starship"):setup()

-- yazi linemode show lines plugin
require("lines-linemode"):setup()

-- NOTE: show user and host name in the header line
-- Header:children_add(function()
-- 	if ya.target_family() ~= "unix" then
-- 		return ""
-- 	end
-- 	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. "  "):fg("blue")
-- end, 500, Header.LEFT)
