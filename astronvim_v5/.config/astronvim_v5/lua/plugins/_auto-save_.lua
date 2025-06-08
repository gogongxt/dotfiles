-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- auto save
return {
  -- {
  --   "pocco81/auto-save.nvim",
  --   config = function() require("auto-save").setup() end,
  -- },
  {
    "okuuva/auto-save.nvim",
    -- version = "^1.0.0", -- see https://devhints.io/semver, alternatively use '*' to use the latest tagged release
    cmd = "ASToggle", -- optional for lazy loading on command
    event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
    opts = {
      -- your config goes here
      -- or just leave it empty :)
    },
  },
  -- {
  --   "djoshea/vim-autoread",
  -- },
}
