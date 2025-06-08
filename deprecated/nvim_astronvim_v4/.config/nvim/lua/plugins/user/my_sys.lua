local M = {}

function M.DEBUG(...)
  local function pack(...)
    return { n = select('#', ...), ... }
  end
  local home_path = os.getenv("HOME")
  local file = io.open(home_path .. "/.config/nvim/.nvim.log", "a") -- 以追加模式打开文件，如果文件不存在则创建
  if file then
    local args = pack(...)
    for i = 1, args.n do
      file:write(tostring(args[i]) .. "\t") -- 将参数转换为字符串并写入文件
    end
    file:write("\n")                        -- 写入换行符
    file:close()                            -- 关闭文件
  else
    print("Failed to open the file for writing.")
  end
end

function GetFilesInFolder(folder)
  local files = {}
  local handle = io.popen("ls \"" .. folder .. "\"")
  local result = handle:read("*a")
  handle:close()
  for filename in result:gmatch("[^\r\n]+") do
    files[#files + 1] = filename
  end
  return files
end

-- @detail: 遍历文件夹底下所有lua文件，把文件名集合所有返回值到一个table
-- 输入文件夹的绝对路径
-- 输出table：文件所有的返回值
function GetDirectoryLuaFileNames(dire_path)
  -- 遍历user目录下的文件
  local res = {}
  local files = GetFilesInFolder(dire_path)
  for _, filename in ipairs(files) do
    -- M.DEBUG("filename", filename)
    if filename:match("%.lua$") then
      -- 移除文件名后缀
      local filenameWithoutExtension = filename:match("(.+)%..+")
      -- M.DEBUG("filenameWithoutExtension", filenameWithoutExtension)
      table.insert(res, filenameWithoutExtension)
    end
  end
  return res
end

-- @detail: 遍历文件夹底下所有lua文件，集合所有返回值到一个table
-- 输入文件夹的绝对路径
-- 输出table：文件所有的返回值
function M.GetDirectoryLuaFileContents(dire_path)
  local file_tables = GetDirectoryLuaFileNames(dire_path)
  local res = {}
  -- 加载user目录下的所有lua文件
  for _, file in ipairs(file_tables) do
    -- require("my_sys").DEBUG("file:", file)
    local content = require(file)
    -- 针对有return情况
    if content and type(content) == "table" then
      -- 针对return {} 单个情况，就组合成一个{}添加
      if #content > 0 and type(content[1]) ~= "table" then
        -- 如果内容是一个非空表，并且第一个元素不是一个表，则手动包裹一层{}，然后添加到结果表中
        table.insert(res, { content })
      else
        -- 如果是 return {{...},{...}}
        for _, item in ipairs(content) do
          table.insert(res, item)
        end
      end
    end
  end

  return res
end

-- 读取配置文件并检查特定的配置项
function M.GetConfig(config_path, field, default_value)
  -- 加载配置文件
  -- local config = require(config_path)
  local status_ok, config = pcall(require, "config_")
  if not status_ok then
    return default_value
  end

  -- 检查配置项是否存在
  local value = config
  for part in field:gmatch("[^.]+") do
    value = value[part]
    if value == nil then
      -- print("Configuration field '" .. field .. "' not found or incomplete")
      return default_value
    end
  end

  -- 配置项存在
  -- print("Value of " .. field .. ":", value)
  -- 这里可以执行相关操作
  return value
end

return M
