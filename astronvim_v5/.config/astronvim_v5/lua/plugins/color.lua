return {
  "catppuccin/nvim",
  name = "catppuccin",
  config = function()
    require("catppuccin").setup {
      flavour = "frappe", -- latte, frappe, macchiato, mocha
    }
  end,
}


