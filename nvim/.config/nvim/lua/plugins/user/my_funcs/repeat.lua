-- Ref: https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3

--[[
How to use:

```lua
local make_repeatable = require("plugins.user.my_funcs.repeat").make_repeatable

["<Leader>gK"] = {
      make_repeatable(function()
          -- do something
      end),
      expr = true, -- NOTE: must set `expr=true` otherwise g@l will be printed
      desc = "",
    },

```
--]]

local M = {}

M.make_repeatable = function(callback)
  return function()
    _G.current_repeat_callback = callback
    vim.go.operatorfunc = "v:lua.current_repeat_callback"
    return "g@l"
  end
end

return M
