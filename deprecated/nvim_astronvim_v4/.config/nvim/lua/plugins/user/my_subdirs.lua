-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
-- 返回指定目录下的所有内容

local res = {}

-- NOTE: 只需要更改这里，添加你需要添加的文件夹
local dires = {
  "plugins",
}

local current_file_name = debug.getinfo(1, "S").source:sub(2)
local current_file_path = current_file_name:match("(.*[/\\])")

for _, dire in ipairs(dires) do
  package.path = package.path .. ";" .. current_file_path .. dire .. "/?.lua"
  local item = require("my_sys").GetDirectoryLuaFileContents(current_file_path .. dire)
  table.insert(res, item)
end

return res
