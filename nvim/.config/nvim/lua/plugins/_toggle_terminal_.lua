-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- NOTE: gogongxt: 以下toggle_terminal函数都参考自lvim源码：
-- https://github.com/LunarVim/LunarVim/blob/master/lua/lvim/core/terminal.lua

local M = {}

local terminal_maps = {
  { vim.o.shell, "<M-`>", "Float Terminal1", "float", nil },
  { vim.o.shell, "<M-Esc>", "Float Terminal2", "float", nil },
  { vim.o.shell, "<M-->", "Horizontal Terminal1", "horizontal", 0.3 },
  { vim.o.shell, "<M-=>", "Horizontal Terminal2", "horizontal", 0.3 },
  { vim.o.shell, "<M-\\>", "Vertical Terminal1", "vertical", 0.4 },
  { vim.o.shell, "<M-BackSpace>", "Vertical Terminal2", "vertical", 0.4 },
}

-- 使用全局 editor 大小，因为 toggleterm 总是从全局空间分割
-- 当已有终端时，toggleterm 会在现有终端窗口内 split，而不是当前窗口
local function get_buf_size() return { width = vim.o.columns, height = vim.o.lines } end

--- Get the dynamic terminal size in cells
---@param direction number
---@param size number
---@return integer
local function get_dynamic_terminal_size(direction, size)
  size = size or 20
  if direction ~= "float" and tostring(size):find(".", 1, true) then
    size = math.min(size, 1.0)
    local buf_sizes = get_buf_size()
    local buf_size = direction == "horizontal" and buf_sizes.height or buf_sizes.width
    return buf_size * size
  else
    return size
  end
end

M.init = function(terminal_execs)
  for i, exec in pairs(terminal_execs) do
    local direction = exec[4] or "float"

    local opts = {
      cmd = exec[1] or vim.o.shell,
      keymap = exec[2],
      label = exec[3],
      -- NOTE: unable to consistently bind id/count <= 9, see #2146
      count = i + 100,
      direction = direction,
      size = function() return get_dynamic_terminal_size(direction, exec[5]) end,
    }

    M.add_exec(opts)
  end
end

M.add_exec = function(opts)
  local binary = opts.cmd:match "(%S+)"
  if vim.fn.executable(binary) ~= 1 then
    -- Log:debug("Skipping configuring executable " .. binary .. ". Please make sure it is installed properly.")
    require("plugins.user.my_sys").DEBUG(
      "Skipping configuring executable " .. binary .. ". Please make sure it is installed properly."
    )
    return
  end

  vim.keymap.set(
    { "n", "t" },
    opts.keymap,
    function() M._exec_toggle { cmd = opts.cmd, count = opts.count, direction = opts.direction, size = opts.size() } end,
    { desc = opts.label, noremap = true, silent = true }
  )
end

M._exec_toggle = function(opts)
  local Terminal = require("toggleterm.terminal").Terminal
  -- local term = Terminal:new { cmd = opts.cmd, count = opts.count, direction = opts.direction }
  -- term:toggle(opts.size, opts.direction)
  local term = Terminal:new {
    size = opts.size,
    cmd = opts.cmd,
    count = opts.count,
    direction = opts.direction,
    float_opts = { border = "curved" },
  }
  term:toggle(opts.size)
end

M.init(terminal_maps)

-- Monkey patch toggleterm 的 open_split
-- 让 horizontal terminal 总是从编辑器底部创建，而不是在已有终端内部分割
local ok, toggleterm_ui = pcall(require, "toggleterm.ui")
if ok then
  local original_open_split = toggleterm_ui.open_split
  toggleterm_ui.open_split = function(size, term)
    if term.direction == "horizontal" then
      -- 总是使用 botright split，从编辑器底部创建
      vim.cmd "botright split"
      toggleterm_ui.resize_split(term, size)
      -- 复用 toggleterm 的 buffer 创建逻辑
      local api = vim.api
      local valid_win = term.window and api.nvim_win_is_valid(term.window)
      local window = valid_win and term.window or api.nvim_get_current_win()
      local valid_buf = term.bufnr and api.nvim_buf_is_valid(term.bufnr)
      local bufnr = valid_buf and term.bufnr or api.nvim_create_buf(false, false)
      api.nvim_win_set_buf(window, bufnr)
      term.window, term.bufnr = window, bufnr
      term:__set_options()
      api.nvim_set_current_buf(bufnr)
    else
      original_open_split(size, term)
    end
  end
end

-- Monkey patch toggleterm 的 Terminal:close
-- 修复：从已有 float 终端的 insert 模式触发 keymap 打开第二个全新 float 终端时，
-- 新终端会落到 normal-terminal 模式而非 insert。
-- 根因：t2 的 open_float 让光标离开 t1 → WinLeave autocmd → handle_term_leave →
-- t1:close() → ui.stopinsert() 执行 stopinsert!。stopinsert! 的"尽快退出"效果是异步的，
-- 会在下一帧覆盖 t2 的 startinsert，导致 t2 落到 nt 模式。
-- 修复：只在 cursor 仍位于被关闭终端的 buffer 时才 stopinsert。当 close 由其他终端
-- 的 open_float 间接触发时，cursor 已不在被关闭的 buffer 中，无需 stopinsert。
-- 上游 issue：akinsho/toggleterm.nvim#657
local ok_term, term_module = pcall(require, "toggleterm.terminal")
if ok_term and term_module and term_module.Terminal and toggleterm_ui then
  term_module.Terminal.close = function(self)
    if self.on_close then self:on_close() end
    toggleterm_ui.close(self)
    if self.bufnr and vim.api.nvim_get_current_buf() == self.bufnr then toggleterm_ui.stopinsert() end
    toggleterm_ui.update_origin_window(self.window)
  end
end

-- 保存并恢复终端 ANSI 颜色，防止被 neovim 主题覆盖
-- 原因：neovim 主题会设置 vim.g.terminal_color_*，覆盖终端模拟器（如 kitty）的颜色配置
local saved_terminal_colors = {}
for i = 0, 15 do
  saved_terminal_colors[i] = vim.g["terminal_color_" .. i]
end
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    for i = 0, 15 do
      vim.g["terminal_color_" .. i] = saved_terminal_colors[i]
    end
  end,
  desc = "Restore terminal colors after colorscheme change",
})

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd "autocmd! TermOpen term://* lua set_terminal_keymaps()"
-- vim.keymap.set("n", "<C-t>", "<cmd>ToggleTerm<cr>")
-- vim.keymap.set("t", "<C-t>", "<cmd>ToggleTerm<cr>")
-- lvim.keys.normal_mode["<C-t>"] = "<cmd>ToggleTerminal<cr>"
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
  vim.keymap.set("t", "<C-[>", [[<C-\><C-n>]], opts)
  -- vim.keymap.set('t', 'jj', [[<C-\><C-n>]], opts) // inconvenient in ranger
  -- vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts) // inconvenient in ranger
  -- vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
  -- Map Ctrl+/ to ESC
  vim.keymap.set("t", "<C-/>", "<Esc>", { noremap = true, silent = true, buffer = 0 })
  vim.keymap.set("t", "<C-_>", "<Esc>", { noremap = true, silent = true, buffer = 0 })
  if pcall(require, "smart-splits") then
    -- for smart-splits
    vim.keymap.set("t", "<C-h>", [[<cmd>lua require('smart-splits').move_cursor_left()<cr>]], opts)
    vim.keymap.set("t", "<C-j>", [[<cmd>lua require('smart-splits').move_cursor_down()<cr>]], opts)
    vim.keymap.set("t", "<C-k>", [[<cmd>lua require('smart-splits').move_cursor_up()<cr>]], opts)
    vim.keymap.set("t", "<C-l>", [[<cmd>lua require('smart-splits').move_cursor_right()<cr>]], opts)
  else
    vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
  end
end

-- return {
--   "akinsho/toggleterm.nvim",
--   opts = function(_, opts)
--     opts.highlights = opts.highlights or {}
--     opts.highlights.FloatBorder = {
--       guifg = "#dd7878",
--     }
--     return opts
--   end,
-- }
return {}
