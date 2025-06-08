-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["<Leader>r"] = { "<cmd>%SnipRun<cr>", desc = "Sniprun" },
  },
  v = {
    ["<Leader>r"] = { "<cmd>'<,'>SnipRun<cr>", desc = "Sniprun" },
  },
}

return {
  -- 支持快速片段化运行代码
  "michaelb/sniprun",
  branch = "master",
  build = "sh install.sh",
  config = function()
    require("sniprun").setup {
      display = {
        -- "Classic",       --# display results in the command-line  area
        -- "VirtualTextOk", --# display ok results as virtual text (multiline is shortened)
        --"VirtualTextErr",          --# display error results as virtual text
        -- "TempFloatingWindow",      --# display results in a floating window
        -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText__
        "Terminal", --# display results in a vertical split
        -- "TerminalWithCode",        --# display results and code history in a vertical split
        -- "NvimNotify",              --# display with the nvim-notify plugin
        -- "Api"                      --# return output to a programming interface
      },
    }
  end,
}
