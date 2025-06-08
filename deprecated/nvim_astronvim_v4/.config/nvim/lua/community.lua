-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.typescript" },
  -- import/override with your plugins folder

  -- noice默认自己安装会和astronvim不兼容
  -- 所以我们用社区配置好的
  -- https://www.reddit.com/r/AstroNvim/comments/16v81f0/help_needed_for_adding_noice_to_astronvim/
  { import = "astrocommunity.utility.noice-nvim" },
}
