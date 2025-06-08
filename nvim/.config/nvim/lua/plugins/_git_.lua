-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

vim.g.gitblame_message_when_not_committed = "" -- set null when nothing commit

-- local k_opts = { noremap = true, silent = true }
local keymap = vim.keymap.set
keymap({ "n" }, "<Leader>gj", "<cmd>lua require('gitsigns').nav_hunk('prev')<cr>", { desc = "Hunk next" })
keymap({ "n" }, "<Leader>gk", "<cmd>lua require('gitsigns').nav_hunk('prev')<cr>", { desc = "Hunk prev" })
-- keymap({ "n"}, "<Leader>gB", {name="123"}, { desc = "Git Blame" })

-- ["<Leader>gB"] = { name = "Git Blame" },
-- ["<Leader>gBw"] = { "<cmd>BlameToggle window<cr>", desc = "Blame window", noremap = true, silent = true },
-- ["<Leader>gBv"] = { "<cmd>BlameToggle virtual<cr>", desc = "Blame virtual", noremap = true, silent = true },
-- local wk = require "which-key"
-- wk.register({
--   ["<leader>gB"] = {
--     name = "+git-blame", -- 子菜单名称（可选）
--     b = { "<cmd>BlameToggle window<cr>", "Blame Window" }, -- <leader>gBb
--     a = { "<cmd>BlameToggle virtual<cr>", "Blame Virtual" }, -- <leader>gBa
--     -- 可以继续添加更多子键
--   },
-- }, { mode = "n" })
-- vim.keymap.set("n", "<leader>gB", "<Nop>", { desc = "Git Blame Menu" })  -- 占位，不执行操作
local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["<Leader>gj"] = {
      "<cmd>lua require('gitsigns').nav_hunk('next')<cr>",
      desc = "Hunk Next",
    },
    ["<Leader>gk"] = {
      "<cmd>lua require('gitsigns').nav_hunk('prev')<cr>",
      desc = "Hunk Prev",
    },
    ["<Leader>gB"] = {
      "",
      desc = "Git Blame",
    },
    ["<Leader>gBw"] = { "<cmd>BlameToggle window<cr>", desc = "Blame window" },
    ["<Leader>gBv"] = { "<cmd>BlameToggle virtual<cr>", desc = "Blame virtual" },
    ["<Leader>gd"] = { "<cmd>lua require('gitsigns').diffthis()<cr>", desc = "Git Giff" },
    ["<Leader>gD"] = { function() require("gitsigns").diffthis "~" end, desc = "Git Giff!" },
    ["<Leader>gg"] = { "<cmd>lua require('plugins.user.my_funcs').git_gitui_toggle()<cr>", desc = "gitui" },
  },
}

return {
  {
    "FabijanZulj/blame.nvim",
    config = function() require("blame").setup() end,
  },
  {
    "f-person/git-blame.nvim",
    -- load the plugin at startup
    event = "VeryLazy",
    -- Because of the keys part, you will be lazy loading this plugin.
    -- The plugin wil only load once one of the keys is used.
    -- If you want to load the plugin at startup, add something like event = "VeryLazy",
    -- or lazy = false. One of both options will work.
    opts = {
      -- your configuration comes here
      -- for example
      enabled = true, -- if you want to enable the plugin
      message_template = " [<date>] [<author>]:<summary>   <<sha>>", -- template for the blame message, check the Message template section for more options
      date_format = "%Y-%m-%d %H:%M:%S", -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },
  },
}
