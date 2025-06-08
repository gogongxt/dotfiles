-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- TODO: auto install luarocks need to check
-- https://github.com/3rd/image.nvim

return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- this plugin needs to run before anything else
    enabled = require("my_sys").GetConfig("config_", "image.image_enabled", false),
    opts = {
      rocks = { "magick" },
    },
  },
  {
    "3rd/image.nvim",
    enabled = require("my_sys").GetConfig("config_", "image.image_enabled", false),
    dependencies = { "luarocks.nvim" },
    config = function()
      -- -- Example for configuring Neovim to load user-installed installed Lua rocks:
      -- at ~ exec $luarocks --local --lua-version=5.1 install magick
      package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?/init.lua;"
      package.path = package.path .. ";" .. vim.fn.expand "$HOME" .. "/.luarocks/share/lua/5.1/?.lua;"
      require("image").setup {
        backend = require("my_sys").GetConfig("config_", "image.backend", "ueberzug"),
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
          },
          neorg = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { "norg" },
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
        tmux_show_only_in_active_window = true, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
      }
    end,
  },
}
