-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- define function to change color for catppuccin*
local function set_diff_highlights()
  vim.cmd [[
    highlight DiffAdd    guibg=#496F4A
    highlight DiffDelete guibg=#4A2E32 guifg=#E78284
    highlight DiffChange   guibg=#000000 guifg=#aaaaaa gui=none
    highlight DiffText     guibg=#cccccc guifg=#ff0000 gui=bold
  ]]
end
-- need set color once when start neovim
if vim.g.colors_name:find "catppuccin" then set_diff_highlights() end
-- make auto change diff color when change colorscheme
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*", -- pair all catppuccin theme（frappe, macchiato, etc）
  callback = function() set_diff_highlights() end,
  desc = "Override diff colors for Catppuccin",
})

vim.opt.fillchars = {
  horiz = "═",
  horizup = "╩",
  horizdown = "╦",
  vert = "║",
  vertleft = "╣",
  vertright = "╠",
  verthoriz = "╬",
}

-- toggle snacks image show
-- Ref: https://github.com/folke/snacks.nvim/issues/1739#issuecomment-3413850508
local disable_snacks_image = function()
  -- Some group names depend on image ID so we find them based on their events
  local events = {
    "BufWinEnter",
    "WinEnter",
    "BufWinLeave",
    "BufEnter",
    "WinClosed",
    "WinNew",
    "WinResized",
    "BufWritePost",
    "WinScrolled",
    "ModeChanged",
    "CursorMoved",
    "BufWipeout",
    "BufDelete",
    "BufWriteCmd",
    "FileType",
    "BufReadCmd",
  }
  local all_autocmds = vim.api.nvim_get_autocmds { event = events }
  local image_autocmds = {}
  local group_set = {}
  for _, autocmd in ipairs(all_autocmds) do
    if autocmd.group_name ~= nil and string.find(autocmd.group_name, "snacks.image", 1, true) then
      image_autocmds[#image_autocmds + 1] = autocmd
      group_set[autocmd.group_name] = true
    end
  end
  -- Save autocmds and augroups for when it is time to re-enable
  _G.image_autocmds = image_autocmds
  _G.image_augroups = group_set
  -- Clean buffer and clear augroups
  Snacks.image.placement.clean()
  for group, _ in pairs(group_set) do
    vim.api.nvim_create_augroup(group, { clear = true })
  end
  -- For toggle
  _G.snacks_disabled = true
end
-- Re-enable snacks.image after it was disabled
-- The function re-creates all autocmds and then re-attaches all buffers that were attached
local enable_snacks_image = function()
  -- Re-create the groups
  for group, _ in pairs(image_augroups) do
    vim.api.nvim_create_augroup(group, { clear = true })
  end
  -- Re-create autocmds. Some keys need to be cleared or modified
  -- so that format from get_autocmds works with create_autocmd
  for _, autocmd in ipairs(image_autocmds) do
    autocmd.group = autocmd.group_name
    if autocmd.command == "" then autocmd.command = nil end
    autocmd.group_name = nil
    local event = autocmd.event
    autocmd.event = nil
    autocmd.id = nil
    if autocmd.buflocal then autocmd.pattern = nil end
    autocmd.buflocal = nil
    vim.api.nvim_create_autocmd(event, autocmd)
  end
  -- Loop over buffers and enable those with compatible filetype
  local bufs = vim.api.nvim_list_bufs()
  local langs = Snacks.image.langs()
  for _, buf in ipairs(bufs) do
    local ft = vim.bo[buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if vim.tbl_contains(langs, lang) then
      -- Make sure the buffer is detached otherwise attach does nothing
      vim.b[buf].snacks_image_attached = false
      Snacks.image.doc.attach(buf)
    end
  end
  _G.snacks_disabled = false
end
local toggle_snacks_image = function()
  if snacks_disabled == nil then _G.snacks_disabled = false end
  if snacks_disabled then
    enable_snacks_image()
  else
    disable_snacks_image()
  end
end

local function toggle_render()
  if vim.bo.filetype == "markdown" then
    vim.cmd "RenderMarkdown toggle"
    toggle_snacks_image()
  elseif vim.bo.filetype == "csv" then
    vim.cmd "CsvViewToggle display_mode=border"
  else
    vim.cmd "Neogen"
  end
end

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    -- delete comments
    ["<leader>Q"] = {
      ":tabclose<cr>",
      desc = "Close Tab",
      noremap = true,
      silent = true,
    },
    ["<leader>ld"] = {
      "<cmd>lua require('plugins.user.my_funcs.delete_comments').delete_comments()<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
    ["<C-/>"] = {
      toggle_render,
      desc = "Toggle Render",
    },
    ["<C-_>"] = {
      toggle_render,
      desc = "Toggle Render",
    },
    ["gn"] = {
      "<cmd>lua require('illuminate').goto_next_reference(true)<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
    ["gp"] = {
      "<cmd>lua require('illuminate').goto_prev_reference(true)<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
    ["<c-g>"] = {
      function()
        local full_path = vim.fn.expand "%:p"
        local total_lines = vim.fn.line "$"
        local current_line = vim.fn.line "."
        local percent = math.modf((current_line / total_lines) * 100)
        vim.notify(string.format('"%s" %d lines --%d%%--', full_path, total_lines, percent), vim.log.levels.INFO)
      end,
      noremap = true,
      silent = true,
    },
  },
  v = {
    -- delete comments
    ["<leader>ld"] = {
      "<cmd>lua require('plugins.user.my_funcs.delete_comments').delete_comments('v')<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
  },
}

-- use for some terminal only support osc52 copy but not paste
local function paste()
  return {
    vim.fn.split(vim.fn.getreg "", "\n"),
    vim.fn.getregtype "",
  }
end

-- ref: https://www.cnblogs.com/sxrhhh/p/18234652/neovim-copy-anywhere
-- 本地环境 判断SSH_CONNECTION在tmux环境下也有用，SSH_TTY有时会失效
-- if os.getenv "SSH_TTY" == nil then
if os.getenv "SSH_CONNECTION" == nil then
  vim.opt.clipboard:append "unnamedplus"
else
  -- remote env
  vim.opt.clipboard:append "unnamedplus"
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy "+",
      ["*"] = require("vim.ui.clipboard.osc52").copy "*",
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
  }
end

-- ref: help jumplist-stack
-- ref: https://www.bilibili.com/video/BV132qUY4EhS/
vim.opt.jumpoptions = "stack"

-- set for vim exec shell cmd
-- vim.o.shellcmdflag = "-ci"
vim.o.shellcmdflag = "-c"

-- minimal number of screen lines
vim.o.scrolloff = 5 -- keep above and below the cursor.
vim.o.sidescrolloff = 8 -- keep left and right of the cursor.

-- NOTE: gxt: Astronvim Feature_or_Bug?
-- https://www.reddit.com/r/AstroNvim/comments/108cir5/keep_word_search_highlighting/
-- https://github.com/AstroNvim/AstroNvim/issues/2109
vim.on_key(nil, vim.api.nvim_get_namespaces()["auto_hlsearch"])

-- For astronvim v5 not set fold by myself so don't need to set anymore
-- set for ufo and statuscol
-- https://github.com/kevinhwang91/nvim-ufo/issues/4#issuecomment-1512772530
-- vim.o.foldcolumn = "1" -- '0' is not bad
-- vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
-- vim.o.foldlevelstart = 99
-- vim.o.foldenable = true
-- vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
-- larger icon
-- vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

-- Set nofixeol and nofixendofline options
vim.opt.fixeol = false
vim.opt.fixendofline = false
