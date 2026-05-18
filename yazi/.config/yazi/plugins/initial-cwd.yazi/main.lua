--- @sync entry

local get_cwd = ya.sync(function(st)
	return st.initial_cwd
end)

local set_cwd = ya.sync(function(st)
	if not st.initial_cwd then
		st.initial_cwd = tostring(cx.active.current.cwd)
	end
end)

local function setup()
	ps.sub("cd", function()
		set_cwd()
	end)
end

local function entry()
	local cwd = get_cwd()
	ya.emit("cd", { cwd })
end

return { entry = entry, setup = setup }
