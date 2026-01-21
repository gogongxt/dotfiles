local ls = require "luasnip"
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- 生成8位16进制随机字符串
local function generate_abbrlink() return string.format("%08x", math.random(0, 0xFFFFFFFF)) end

return {
  s("hexo_blog_template", {
    t { "---", "title: " },
    f(function(args) return vim.fn.expand "%:t:r" end),
    t { "", "date: " },
    f(function()
      local date = os.date "%Y-%m-%d %H:%M:%S"
      return date
    end),
    t { "", "abbrlink: " },
    f(generate_abbrlink),
    t { "", "tags:", "  - ", "categories:", "  - ", "series:", "---", "" },
    i(0),
  }),
}
