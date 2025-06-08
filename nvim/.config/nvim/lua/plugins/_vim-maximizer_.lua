-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["<Leader>z"] = { "<cmd>MaximizerToggle<cr>", desc = "Max current buffer" },
  },
}

return {
  "szw/vim-maximizer",
  event = "VeryLazy",
}
