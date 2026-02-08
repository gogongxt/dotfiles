-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- import/override with your plugins folder
  { import = "astrocommunity.recipes.picker-nvchad-theme" },
  { import = "astrocommunity.utility.noice-nvim" },

  -- debug dap
  { import = "astrocommunity.debugging.nvim-dap-view" },
  { import = "astrocommunity.debugging.nvim-dap-repl-highlights" },
}
