-- 这个文件是用来写你自己的一些自定义独立的配置的
-- 使用就是把这个文件重命名成 my_config.lua
-- 这些配置不会更新到git中

local M = {}

-- 是否使能neovim显示图片，涉及插件有leetcode.nvim和image.nvim
M.image_enabled = false

-- 远程ssh连接时，不能使用鼠标复制，就可以用这个，独立出鼠标
vim.o.mouse = "c"

return M
