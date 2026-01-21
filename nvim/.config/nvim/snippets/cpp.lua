local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  -- leetcode prefix with dynamic HOME path
  s("leetcode_prefix", {
    t { "#include <bits/stdc++.h>", "", "" },
    t '#include "',
    t(vim.fn.expand "$HOME" .. "/Projects/debugstream/debugstream.hpp"),
    t { '"', "", "using namespace std;", "", "" },
    i(0),
  }),

  -- leetcode suffix
  s("leetcode_suffix", {
    t { "int main(int argc, char* argv[]) {", "  Solution solution," },
    i(1, ""),
    t { "", "  return 0;", "}" },
    i(0),
  }),
}
