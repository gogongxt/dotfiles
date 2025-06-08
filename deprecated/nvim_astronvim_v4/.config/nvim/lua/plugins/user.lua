-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
-- 这个文件就是用导入user目录下的所有配置

local current_file_name = debug.getinfo(1, "S").source:sub(2)
local current_file_path = current_file_name:match "(.*[/\\])"
-- 添加到包寻找内容
-- 添加当前路径/user
package.path = package.path .. ";" .. current_file_path .. "user/?.lua"

-- 添加配置文件所在路径下的lua文件
-- package.path = package.path .. ";" .. vim.fn.stdpath "config" .. "/?.lua"
-- 添加配置文件
-- local _, _ = pcall(require, "config_")
-- require("my_sys").DEBUG("package.path", package.path)

local res = require("my_sys").GetDirectoryLuaFileContents(current_file_path .. "user")
-- 返回user_config
return res
