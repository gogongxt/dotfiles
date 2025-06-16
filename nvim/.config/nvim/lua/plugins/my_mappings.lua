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

          -- universal
          ["<Leader>h"] = { "<cmd>nohl<cr>", desc = "<cmd>nohl" },
          ["q"] = { "<Nop>", desc = "disable micro" },

          -- save file
          ["<leader>w"] = { "<cmd>w<cr>", desc = "Save File" },
          ["<C-s>"] = { "<cmd>w<cr>", desc = "Save File" },
          ["<Leader>W"] = { function() require("plugins.user.my_funcs").sudo_write() end, desc = "Write with root" },

          -- run cmd
          ["<Leader>R"] = {
            -- function()
            --   vim.cmd('normal! V')  -- 进入可视模式
            --   my_funcs.execute_and_print_cmd()
            -- end,
            "V<cmd>lua require('plugins.user.my_funcs').execute_and_print_cmd()<cr>",
            desc = "Run cmd",
            noremap = true,
            silent = true,
          },

          -- go to file
          ["gf"] = {
            "<cmd>lua require('plugins.user.my_funcs').extract_file_info()<cr>",
            desc = "Goto file",
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

          ["<Leader>R"] = {
            "<cmd>lua require('plugins.user.my_funcs').execute_and_print_cmd()<cr>",
            desc = "Run cmd",
            noremap = true,
            silent = true,
          },

          -- go to file
          ["gf"] = {
            "<cmd>lua require('plugins.user.my_funcs').extract_file_info(require('plugins.user.my_funcs').get_text('v'))<cr>",
            desc = "Goto file",
          },

          -- delete empty lines
          ["<Leader>lc"] = {
            "<cmd>lua require('plugins.user.my_funcs').DeleteEmptyLinesInVisual()<CR>",
            desc = "Clear Empty Lines",
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
