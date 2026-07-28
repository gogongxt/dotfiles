if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- TODO: add image support for snacks image and use ft https://github.com/kawre/leetcode.nvim/pull/158

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    -- leetcode
    ["<Leader>L"] = { group = "Leetcode" },
    ["<Leader>LL"] = {
      function()
        if vim.fn.exists ":Leet" ~= 2 then
          vim.cmd "Leet"
          return
        end
        local ok, state = pcall(function() return _Lc_state.menu end)
        if ok and state and state.winid and vim.api.nvim_win_is_valid(state.winid) then
          vim.cmd "Leet menu"
        else
          vim.cmd "Leet"
        end
      end,
      desc = "Leet menu",
      noremap = true,
      silent = true,
    },
    ["<leader>Ll"] = { "<cmd>Leet tabs<CR>", desc = "Leet tabs", noremap = true, silent = true },
    ["<leader>Lr"] = { "<cmd>Leet run<CR>", desc = "Leet run", noremap = true, silent = true },
    ["<leader>Lt"] = { "<cmd>Leet console<CR>", desc = "Leet console", noremap = true, silent = true },
    ["<leader>Ls"] = { "<cmd>Leet submit<CR>", desc = "Leet submit", noremap = true, silent = true },
    ["<leader>Lc"] = { "<cmd>Leet cache<CR>", desc = "Leet cache", noremap = true, silent = true },
    ["<leader>Li"] = { "<cmd>Leet info<CR>", desc = "Leet info", noremap = true, silent = true },
    ["<leader>L<tab>"] = { "<cmd>Leet desc<CR>", desc = "Leet desc", noremap = true, silent = true },
  },
}

return {
  "gogongxt/leetcode.nvim",
  cmd = "Leet",
  build = ":TSUpdate html",
  dependencies = {
    "folke/snacks.nvim",
  },
  opts = {
    lang = "cpp",

    cn = { -- leetcode.cn
      enabled = true, ---@type boolean
      translator = false, ---@type boolean
      translate_problems = true, ---@type boolean
    },

    storage = {
      home = "~/Projects/leetcode/nvim",
    },

    plugins = {
      non_standalone = false,
    },

    injector = { ---@type table<lc.lang, lc.inject>
      ["cpp"] = {
        before = {
          "#ifdef __linux__",
          "",
          "#include <bits/stdc++.h>",
          "",
          '#include "/home/gogongxt/Projects/debugstream/include/debugstream/debugstream.h"',
          '#include "/home/gogongxt/Projects/debugstream/include/debugstream/detail/leetcode.h"',
          '#include "/home/gogongxt/Projects/debugstream/include/debugstream/detail/leetcode_list.h"',
          '#include "/home/gogongxt/Projects/debugstream/include/debugstream/detail/leetcode_tree.h"',
          "",
          "#elif __APPLE__",
          "",
          '#include "/Users/gogongxt/Projects/debugstream/include/debugstream/debugstream.h"',
          '#include "/Users/gogongxt/Projects/debugstream/include/debugstream/detail/leetcode.h"',
          '#include "/Users/gogongxt/Projects/debugstream/include/debugstream/detail/leetcode_list.h"',
          '#include "/Users/gogongxt/Projects/debugstream/include/debugstream/detail/leetcode_tree.h"',
          '#include "stdc++.h"',
          "",
          "#elif _WIN32",
          "",
          "#endif",
          "",
          "using namespace std;",
        },
        after = {
          "int main() {",
          '  std::cout << "hello ";',
          '  std::cout << "world!" << std::endl;',
          "  Solution solution;",
          "}",
        },
      },
    },
    keys = {
      toggle = { "q", "<Esc>" }, ---@type string|string[]
      confirm = { "<CR>" }, ---@type string|string[]
      reset_testcases = "r", ---@type string
      use_testcase = "a", ---@type string
      focus_testcases = "<C-h>", ---@type string
      focus_result = "<C-l>", ---@type string
    },

    picker = { provider = "snacks-picker" },

    image_support = false,
  },
}
