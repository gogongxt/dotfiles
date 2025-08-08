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

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    -- delete comments
    ["<leader>ld"] = {
      "<cmd>lua require('plugins.user.my_funcs.delete_comments').delete_comments()<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
    ["<C-_>"] = {
      function()
        if vim.bo.filetype == "markdown" then
          vim.cmd "RenderMarkdown toggle"
        elseif vim.bo.filetype == "csv" then
          vim.cmd "CsvViewToggle display_mode=border"
        else
          vim.cmd "Neogen"
        end
      end,
      desc = "Toggle Render",
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

-- 支持%跳转"<>"
vim.opt.matchpairs:append "<:>"
