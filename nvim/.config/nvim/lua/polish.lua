-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.opt.errorbells = false
vim.opt.visualbell = true

vim.cmd.colorscheme "catppuccin"

-- define function to change color for catppuccin*
local function set_diff_highlights()
  vim.cmd [[
    " like git-delta plus-style / minus-style (also used by unified diff buffers)
    highlight DiffAdd       guibg=#496F4A
    highlight DiffDelete    guibg=#4A2E32 guifg=#E78284
    " global fallback when side is unknown (e.g. BASE window in 3-way merge)
    highlight DiffChange    guibg=#000000 guifg=#aaaaaa gui=none
    highlight DiffText      guibg=#25533D guifg=#00ff00 gui=bold
    " per-side groups, mapped per window via 'winhl' (delta minus/plus-emph-style)
    highlight DiffMinusLine guibg=#4A2E32 guifg=#E78284
    highlight DiffMinusEmph guibg=#cccccc guifg=#ff0000 gui=bold
    highlight DiffPlusLine  guibg=#496F4A
    highlight DiffPlusEmph  guibg=#25533D guifg=#00ff00 gui=bold
  ]]
end
-- vim has only one DiffChange/DiffText, split them per window with 'winhl':
-- in vimdiff the minus/plus side are different windows, so each side can
-- have its own colors like git-delta
local function set_diff_winhl(win, line, emph)
  local parts = {}
  if vim.wo[win].winhl ~= "" then
    for _, entry in ipairs(vim.split(vim.wo[win].winhl, ",", { plain = true, trimempty = true })) do
      -- keep entries not managed here
      local from = entry:match "^([^:]+):"
      if from ~= "DiffChange" and from ~= "DiffText" and from ~= "DiffTextAdd" then
        parts[#parts + 1] = entry
      end
    end
  end
  if line and vim.fn.hlexists(line) == 1 then
    parts[#parts + 1] = "DiffChange:" .. line
    parts[#parts + 1] = "DiffText:" .. emph
    -- nvim 0.12+: purely inserted chars, no counterpart in the other buffer
    parts[#parts + 1] = "DiffTextAdd:" .. emph
  end
  vim.wo[win].winhl = table.concat(parts, ",")
end
-- like git-delta: leftmost diff window = minus (old), rightmost = plus (new).
-- middle windows (e.g. BASE in a 3-way merge) keep the global fallback.
local function apply_diff_side_highlights()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_is_valid(win) then
        if vim.wo[win].diff then
          local pos = vim.api.nvim_win_get_position(win)
          wins[#wins + 1] = { win = win, col = pos[2], row = pos[1] }
        else
          -- clear leftover entries on windows that left diff mode (:diffoff)
          local hl = vim.wo[win].winhl
          if hl:find "DiffChange:" or hl:find "DiffText:" or hl:find "DiffTextAdd:" then
            set_diff_winhl(win)
          end
        end
      end
    end
    table.sort(wins, function(a, b)
      if a.col ~= b.col then return a.col < b.col end
      return a.row < b.row
    end)
    for i, w in ipairs(wins) do
      if i == 1 and #wins >= 2 then
        set_diff_winhl(w.win, "DiffMinusLine", "DiffMinusEmph")
      elseif i == #wins and #wins >= 2 then
        set_diff_winhl(w.win, "DiffPlusLine", "DiffPlusEmph")
      else
        set_diff_winhl(w.win) -- single or middle window: global fallback
      end
    end
  end
end
-- need set color once when start neovim
if vim.g.colors_name:find "catppuccin" then set_diff_highlights() end
-- make auto change diff color when change colorscheme
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*", -- pair all catppuccin theme（frappe, macchiato, etc）
  callback = function() set_diff_highlights() end,
  desc = "Override diff colors for Catppuccin",
})
-- apply per-side diff colors when a window enters/leaves diff mode
-- (vimdiff, :diffsplit, :diffthis, difftool, ...)
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "diff",
  callback = vim.schedule_wrap(apply_diff_side_highlights),
  desc = "Split diff highlights per side (minus/plus)",
})
-- OptionSet is not fired during startup (e.g. nvim -d), and diff windows may close
vim.api.nvim_create_autocmd({ "VimEnter", "WinClosed" }, {
  callback = vim.schedule_wrap(apply_diff_side_highlights),
  desc = "Re-apply per-side diff highlights",
})

-- merge fillchars config, remain fold icon
local fillchars = vim.opt.fillchars:get() or {}
vim.opt.fillchars = vim.tbl_extend("force", fillchars, {
  horiz = "═",
  horizup = "╩",
  horizdown = "╦",
  vert = "║",
  vertleft = "╣",
  vertright = "╠",
  verthoriz = "╬",
})

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
