-- How to run this test file
-- nvim --headless -c "luafile $HOME/.config/nvim/lua/plugins/user/my_funcs/goto_file_test.lua" -c "qa"
-- Tests for goto_file.lua

-- Add the current directory to package.path so we can require goto_file
local home_dir = os.getenv "HOME"
package.path = package.path
    .. ";"
    .. home_dir
    .. "/.config/nvim/lua/?.lua;"
    .. home_dir
    .. "/.config/nvim/lua/plugins/user/my_funcs/?.lua"

local goto_file = require "goto_file"

-- 虚拟测试环境，假装文件是存在的，才好测试函数goto_file
-- Mock vim functions for testing
local original_vim = _G.vim
local mock_vim = {
  fn = {
    getcwd = function() return "/home/user/project" end,
    fnameescape = function(path) return path end,
  },
  loop = {
    fs_stat = function(path)
      -- Mock file system stat to return true for existing files
      local existing_files = {
        ["/home/user/project/src/main.lua"] = true,
        ["/home/user/project/test.txt"] = true,
        ["/home/user/config.lua"] = true,
        ["/tmp/file.lua"] = true,
        ["/home/user/project/src/module/submodule/file.lua"] = true,
      }
      return existing_files[path]
    end,
  },
  api = {
    nvim_get_current_line = function() return "" end,
    nvim_err_writeln = function(msg) print("ERROR: " .. msg) end,
  },
}

-- Setup and teardown
local function setup() _G.vim = mock_vim end

local function teardown() _G.vim = original_vim end

-- Test helper function
local function test_parse_line(name, input, expected_file, expected_line, expected_col)
  print("Testing: " .. name)

  -- Mock HOME environment variable
  local old_getenv = os.getenv
  os.getenv = function(key)
    if key == "HOME" then return "/home/user" end
    return old_getenv(key)
  end

  local file, line, col = goto_file.parse_line(input, "/home/user/project", "/home/user")

  os.getenv = old_getenv

  if file == expected_file and line == expected_line and col == expected_col then
    print "  PASSED"
  else
    print "  FAILED"
    print(
      "    Expected: " .. tostring(expected_file) .. ":" .. tostring(expected_line) .. ":" .. tostring(expected_col)
    )
    print("    Got: " .. tostring(file) .. ":" .. tostring(line) .. ":" .. tostring(col))
  end
end

-- Run tests
setup()

print "=== Testing parse_line function ==="

-- Test absolute paths
test_parse_line("Absolute path with line and column", "/tmp/file.lua:10:5", "/tmp/file.lua", "10", "5")
test_parse_line("Absolute path with line only", "/tmp/file.lua:10", "/tmp/file.lua", "10", nil)
test_parse_line("Absolute path only", "/tmp/file.lua", "/tmp/file.lua", nil, nil)

-- Test HOME paths
test_parse_line("HOME path with line and column", "$HOME/config.lua:5:10", "/home/user/config.lua", "5", "10")
test_parse_line("HOME path with line only", "$HOME/config.lua:5", "/home/user/config.lua", "5", nil)
test_parse_line("HOME path only", "$HOME/config.lua", "/home/user/config.lua", nil, nil)

-- Test ~ paths
test_parse_line("Tilde path with line and column", "~/config.lua:5:10", "/home/user/config.lua", "5", "10")
test_parse_line("Tilde path with line only", "~/config.lua:5", "/home/user/config.lua", "5", nil)
test_parse_line("Tilde path only", "~/config.lua", "/home/user/config.lua", nil, nil)

-- Test relative paths with directories
test_parse_line(
  "Relative path with directories and line/column",
  "src/module/submodule/file.lua:15:20",
  "/home/user/project/src/module/submodule/file.lua",
  "15",
  "20"
)
test_parse_line(
  "Relative path with directories and line",
  "src/module/submodule/file.lua:15",
  "/home/user/project/src/module/submodule/file.lua",
  "15",
  nil
)
test_parse_line(
  "Relative path with directories only",
  "src/module/submodule/file.lua",
  "/home/user/project/src/module/submodule/file.lua",
  nil,
  nil
)

-- Test simple filenames with extensions
test_parse_line(
  "Simple filename with extension and line/column",
  "test.txt:100:50",
  "/home/user/project/test.txt",
  "100",
  "50"
)
test_parse_line("Simple filename with extension and line", "test.txt:100", "/home/user/project/test.txt", "100", nil)
test_parse_line("Simple filename with extension only", "test.txt", "/home/user/project/test.txt", nil, nil)

-- Test IPython-style format
test_parse_line("IPython-style format", "File /tmp/file.lua:25, in something", "/tmp/file.lua", "25", nil)

-- Test edge cases
test_parse_line("Path with spaces", "/path with spaces/file.lua:10:5", "/path", nil, nil) -- Should partially match up to the space
test_parse_line("Invalid input", "not a path", nil, nil, nil)                             -- Should return nil

-- Test extract_file_info function
print "\n=== Testing extract_file_info function ==="
-- This would require more complex mocking of Neovim API functions
print "extract_file_info testing: SKIPPED (requires more complex Neovim API mocking)"

teardown()

print "\n=== All tests completed ==="
