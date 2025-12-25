local opts = { noremap = true, silent = true }
local keymap = vim.keymap
keymap.set("i", "jk", "<Esc>", opts)
keymap.set("n", "<leader>\\", "<C-w>v", opts)
keymap.set("n", "<leader><BS>", "<C-w>v", opts)
keymap.set("n", "<leader>-", "<C-w>s", opts)
keymap.set("n", "<C-s>", "<cmd>w<cr>", opts)
-- keymap.set("n", "<S-h>", "<cmd>bpre<cr>", opts)
-- keymap.set("n", "<S-l>", "<cmd>bnext<cr>", opts)
-- keymap.set("n", "<S-h>", "<cmd>lua require('astrocore.buffer').nav(vim.v.count1)<cr>", opts)
-- keymap.set("n", "<S-l>", "<cmd>lua require('astrocore.buffer').nav(-vim.v.count1)<cr>", opts)
--

-- Visual --
-- Stay in indent mode
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)
-- Move text up and down
keymap.set("v", "<A-j>", ":m .+1<CR>==", opts)
keymap.set("v", "<A-k>", ":m .-2<CR>==", opts)
-- Visual Block --
-- Move text up and down
keymap.set("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap.set("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap.set("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap.set("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- nvim tab operation
for i = 1, 9 do
  vim.keymap.set("n", "<Leader>" .. i, function()
    local tab_count = vim.fn.tabpagenr "$"
    if i <= tab_count then
      -- Tab exists, just switch to it
      vim.cmd(i .. "tabnext")
    elseif i == tab_count + 1 then
      -- Next sequential tab, create it
      vim.cmd "tabnew"
    else
      -- Trying to jump to non-sequential tab
      vim.notify("Can't jump to tab " .. i .. ". Create tab " .. (tab_count + 1) .. " first.", vim.log.levels.WARN)
    end
  end, { desc = i <= 1 and "Go to tab " .. i or "Go to or create tab " .. i })
end

local function move_buf_to_tab(n)
  local cur_buf = vim.api.nvim_get_current_buf()
  local tabs = vim.api.nvim_list_tabpages()
  local tab_count = #tabs
  -- 第一步：在当前窗口用一个空 buffer 替换掉要移动的 buffer
  -- 防止 hide/close 导致 E444 “关闭最后窗口”
  vim.cmd "enew" -- 当前 window 切到一个新的空 buffer (scratch buffer)
  -- 第二步：如果目标 tab 存在，直接切过去
  if n <= tab_count then
    vim.api.nvim_set_current_tabpage(tabs[n])
    vim.cmd("buffer " .. cur_buf)
    return
  end
  -- 第三步：目标 tab 不存在，创建一个新的 tab 再移动过去
  vim.cmd "tabnew"
  local new_tabs = vim.api.nvim_list_tabpages()
  local new_tab = new_tabs[#new_tabs]
  vim.api.nvim_set_current_tabpage(new_tab)
  vim.cmd("buffer " .. cur_buf)
end
for i = 1, 9 do
  vim.keymap.set(
    "n",
    "<leader>bm" .. i,
    function() move_buf_to_tab(i) end,
    { desc = "Move current buffer to tab " .. i }
  )
end

return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        n = {
          -- keymap.set("n", "<leader>S", "<cmd>set invspell<cr>", opts) -- https<cmd>//vimtricks.com/p/vim-spell-check/

          L = {
            function() require("astrocore.buffer").nav(vim.v.count1) end,
            desc = "Next buffer",
          },
          H = {
            function() require("astrocore.buffer").nav(-vim.v.count1) end,
            desc = "Previous buffer",
          },
          ["<Leader>H"] = {
            function() require("astrocore.buffer").move(-vim.v.count1) end,
            desc = "Move buffer tab left",
          },
          ["<Leader>L"] = {
            function() require("astrocore.buffer").move(vim.v.count1) end,
            desc = "Move buffer tab right",
          },

          -- universal
          ["<Leader>h"] = { "<cmd>nohl<cr>", desc = "<cmd>nohl" },
          ["q"] = { "<Nop>", desc = "disable micro" },

          -- save file
          ["<leader>w"] = { "<cmd>w<cr>", desc = "Save File" },
          ["<C-s>"] = { "<cmd>w<cr>", desc = "Save File" },
          ["<Leader>W"] = {
            function() require("plugins.user.my_funcs.sudo_write").sudo_write() end,
            desc = "Write with root",
          },

          -- run cmd
          ["<Leader>R"] = {
            "<cmd>lua require('plugins.user.my_funcs.execute_and_print_cmd').execute_and_print_cmd()<cr>",
            desc = "Run cmd",
            noremap = true,
            silent = true,
          },

          -- go to file
          ["gf"] = {
            "<cmd>lua require('plugins.user.my_funcs.goto_file').extract_file_info()<cr>",
            desc = "Goto file",
            noremap = true,
            silent = true,
          },

          -- delete empty lines
          ["<Leader>lc"] = {
            "<cmd>lua require('plugins.user.my_funcs.delete_empty_lines').delete_empty_lines()<CR>",
            desc = "Delete Empty Lines",
            noremap = true,
            silent = true,
          },

          -- change to tab
          -- TODO: add tabs
          -- ["<Leader>t"] = { name = "Tabs" },
          -- ["<Leader>t<C-n>"] = { "<cmd>tabnew<cr>", desc = "New tab", noremap = true, silent = true },
          -- ["<Leader>tn"] = { "<cmd>tabnext<cr>", desc = "New tab", noremap = true, silent = true },
          -- ["<Leader>tp"] = { "<cmd>tabprevious<cr>", desc = "New tab", noremap = true, silent = true },
        },
        v = {
          -- This will not change the clipboard content in V mode
          ["p"] = { '"_dP', desc = "", noremap = true, silent = true },

          -- go to file
          ["gf"] = {
            "<cmd>lua require('plugins.user.my_funcs.goto_file').extract_file_info(require('plugins.user.my_funcs').get_text('v'))<cr>",
            desc = "Goto file",
          },

          -- delete empty lines
          ["<Leader>lc"] = {
            "<cmd>lua require('plugins.user.my_funcs.delete_empty_lines').delete_empty_lines('v')<CR>",
            desc = "Delete Empty Lines",
            noremap = true,
            silent = true,
          },
        },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      mappings = {
        n = {
          ["<Leader>j"] = {
            "<cmd>ClangdSwitchSourceHeader<cr>",
            desc = "Jump between source and head file",
          },
        },
      },
    },
  },
}
