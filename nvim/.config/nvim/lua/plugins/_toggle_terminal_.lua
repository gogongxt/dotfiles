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

-- 这里原来是用的buffer size为基准
--- Get current buffer size
---@return {width: number, height: number}
-- local function get_buf_size()
--   local cbuf = vim.api.nvim_get_current_buf()
--   local bufinfo = vim.tbl_filter(function(buf)
--     return buf.bufnr == cbuf
--   end, vim.fn.getwininfo(vim.api.nvim_get_current_win()))[1]
--   if bufinfo == nil then
--     return { width = -1, height = -1 }
--   end
--   return { width = bufinfo.width, height = bufinfo.height }
-- end
-- 我改成了用总共窗口的size
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
  local term = Terminal:new { size = opts.size, cmd = opts.cmd, count = opts.count, direction = opts.direction }
  term:toggle(opts.size)
end

M.init(terminal_maps)

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd "autocmd! TermOpen term://* lua set_terminal_keymaps()"
-- vim.keymap.set("n", "<C-t>", "<cmd>ToggleTerm<cr>")
-- vim.keymap.set("t", "<C-t>", "<cmd>ToggleTerm<cr>")
-- lvim.keys.normal_mode["<C-t>"] = "<cmd>ToggleTerminal<cr>"
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
  -- vim.keymap.set('t', 'jj', [[<C-\><C-n>]], opts) // inconvenient in ranger
  -- vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts) // inconvenient in ranger
  -- vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
  -- Map Ctrl+/ to ESC
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
