if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    -- leetcode
    ["<Leader>L"] = { name = "Leetcode" },
    ["<Leader>Ll"] = { "<cmd>Leet list<CR>", desc = "Leet list", noremap = true, silent = true },
    ["<Leader>Lm"] = { "<cmd>Leet menu<CR>", desc = "Leet menui", noremap = true, silent = true },
    -- [<Leader>"Lt"] = { "<cmd>Leet tabs<CR>", "desc = Leet tabs" , noremap = true, silent = true},
    ["<leader>Lr"] = { "<cmd>Leet run<CR>", desc = "Leet run", noremap = true, silent = true },
    ["<leader>Lt"] = { "<cmd>Leet test<CR>", desc = "Leet test", noremap = true, silent = true },
    ["<leader>Ls"] = { "<cmd>Leet submit<CR>", desc = "Leet submit", noremap = true, silent = true },
    ["<leader>Lc"] = { "<cmd>Leet cache<CR>", desc = "Leet cache", noremap = true, silent = true },
    ["<leader>Li"] = { "<cmd>Leet info<CR>", desc = "Leet info", noremap = true, silent = true },
    ["<leader>L<tab>"] = { "<cmd>Leet desc<CR>", desc = "Leet desc", noremap = true, silent = true },
    ["<leader>Lv"] = { "<cmd>Leet console<CR>", desc = "Leet console", noremap = true, silent = true },
  },
}

return {
  -- 在neovim中刷leetcode
  enabled = require("my_sys").GetConfig("config_", "leetcode.leetcode_enabled", true),

  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim", -- required by telescope
    "MunifTanjim/nui.nvim",

    -- optional
    "nvim-treesitter/nvim-treesitter",
    "rcarriga/nvim-notify",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    -- configuration goes here
    --
    ---@type lc.lang
    -- lang = "cpp",
    lang = require("my_sys").GetConfig("config_", "leetcode.lang", "cpp"),
    cn = { -- leetcode.cn
      -- enabled = true, ---@type boolean
      -- translator = false, ---@type boolean
      -- translate_problems = true, ---@type boolean
      enabled = require("my_sys").GetConfig("config_", "leetcode.cn.cn_enabled", true),
      translator = require("my_sys").GetConfig("config_", "leetcode.cn.translator", false),
      translate_problems = require("my_sys").GetConfig("config_", "leetcode.cn.translate_problems", true),
    },
    injector = { ---@type table<lc.lang, lc.inject>
      ["cpp"] = {
        before = {
          "#ifdef __linux__",
          "#include <bits/stdc++.h>",
          "",
          '#include "/home/gxt_kt/Projects/debugstream/debugstream.hpp"',
          '#include "/home/gxt_kt/.local/share/nvim/leetcode/nodetree.hpp"',
          "#elif __APPLE__",
          '#include "/Users/gxt_kt/Projects/debugstream/debugstream.hpp"',
          '#include "/Users/gxt_kt/.local/share/nvim/leetcode/nodetree.hpp"',
          '#include "stdc++.h"',
          "#elif _WIN32",
          "#endif",
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
      ["java"] = {
        before = "import java.util.*;",
      },
    },
    keys = {
      toggle = { "q", "<Esc>" }, ---@type string|string[]
      confirm = { "<CR>" }, ---@type string|string[]

      reset_testcases = "r", ---@type string
      use_testcase = "U", ---@type string
      focus_testcases = "<C-h>", ---@type string
      focus_result = "<C-l>", ---@type string
    },

    ---@type boolean
    image_support = (function()
      local leetcode_show_image = require("my_sys").GetConfig("config_", "leetcode.show_image", false)
      local image_enabled = require("my_sys").GetConfig("config_", "image.image_enabled", false)
      return image_enabled and leetcode_show_image
    end)(), -- setting this to `true` will disable question description wrap
  },
}
