local M = {}

-- themes: https://vimcolorschemes.com/
local theme = "catppuccin"

if theme == "tokyonight" then
  lvim.colorscheme = "tokyonight-storm"
elseif theme == "gruvbox" then
  lvim.colorscheme = "gruvbox"
elseif theme == "onedarker" then
  lvim.colorscheme = "onedarker"
elseif theme == "material" then
  -- 'marko-cerovac/material.nvim',
  lvim.colorscheme = "material"
  vim.g.material_style = "palenight"
  -- lvim.builtin.lualine.options.theme = "auto"
  -- lvim.builtin.lualine.options.theme = "material-nvim"
  -- lvim.builtin.lualine.options.theme="material-stealth"
elseif theme == "catppuccin" then
  vim.g.catppuccin_flavour = "frappe" -- latte, frappe, macchiato, mocha
  lvim.colorscheme = "catppuccin"
elseif theme == "everforest" then
  lvim.colorscheme = "everforest"
  -- vim.g.everforest_background = "soft"
end


M.plugins_theme = {
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    "EdenEast/nightfox.nvim"
  },
  {
    "sainnhe/everforest"
  },
  {
    "morhetz/gruvbox",
  },
  {
    "projekt0n/github-nvim-theme",
  },
  {
    "NLKNguyen/papercolor-theme",
  },
  {
    "marko-cerovac/material.nvim",
    config = function()
      require("material").setup({
        contrast = {
          terminal = false,            -- Enable contrast for the built-in terminal
          sidebars = false,            -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
          floating_windows = false,    -- Enable contrast for floating windows
          cursor_line = false,         -- Enable darker background for the cursor line
          non_current_windows = false, -- Enable darker background for non-current windows
          filetypes = {},              -- Specify which filetypes get the contrasted (darker) background
        },
        styles = {
          -- Give comments style such as bold, italic, underline etc.
          comments = { italic = true },
          strings = { bold = true },
          keywords = { underline = false },
          functions = { bold = true, undercurl = false },
          variables = {},
          operators = {},
          types = {},
        },
        plugins = { -- Uncomment the plugins that you use to highlight them
          -- Available plugins:
          "dap",
          "dashboard",
          "gitsigns",
          "hop",
          "indent-blankline",
          "lspsaga",
          "mini",
          "neogit",
          "nvim-cmp",
          "nvim-navic",
          "nvim-tree",
          "nvim-web-devicons",
          "sneak",
          "telescope",
          "trouble",
          "which-key",
        },
        disable = {
          colored_cursor = false, -- Disable the colored cursor
          borders = false,        -- Disable borders between verticaly split windows
          background = false,     -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
          term_colors = false,    -- Prevent the theme from setting terminal colors
          eob_lines = false,      -- Hide the end-of-buffer lines
        },
        high_visibility = {
          lighter = false,         -- Enable higher contrast text for lighter style
          darker = false,          -- Enable higher contrast text for darker style
        },
        lualine_style = "default", -- Lualine style ( can be 'stealth' or 'default' )
        async_loading = true,      -- Load parts of the theme asyncronously for faster startup (turned on by default)
        -- If you want to everride the default colors, set this to a function
        -- custom_colors = nil,
        custom_colors = function(colors)
          -- colors.editor.selection = "#ff0000"
        end,
        -- change can refer here : https://github.com/marko-cerovac/material.nvim/issues/126
        --
        custom_highlights = {
          IncSearch = { fg = "#000000", bg = "#ECF9ff", underline = true },
          Search = { fg = "#000000", bg = "#ECF9ff", bold = true },
          -- change hop-nvim color
          HopNextKey = { fg = "#ff0000", bold = true },
          -- HopNextKey1 = { fg = "#00ff00", bold = true },
          -- HopNextKey2 = { fg = "#0000ff" },
        }, -- Overwrite highlights with your own
      })
    end,
  },
}


-- CycleColors
-- Ref: https://neovim.discourse.group/t/creating-a-color-picker-using-telescope/1986
-- In order to mapp this function you have to map the command below:
-- :lua require('${file}').choose_colors()
M.choose_colors = function()
  local actions = require "telescope.actions"
  local actions_state = require "telescope.actions.state"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local sorters = require "telescope.sorters"
  local dropdown = require "telescope.themes".get_dropdown()

  local function enter(prompt_bufnr)
    local selected = actions_state.get_selected_entry()
    local cmd = 'colorscheme ' .. selected[1]
    vim.cmd(cmd)
    actions.close(prompt_bufnr)
  end

  local function next_color(prompt_bufnr)
    actions.move_selection_next(prompt_bufnr)
    local selected = actions_state.get_selected_entry()
    local cmd = 'colorscheme ' .. selected[1]
    vim.cmd(cmd)
  end

  local function prev_color(prompt_bufnr)
    actions.move_selection_previous(prompt_bufnr)
    local selected = actions_state.get_selected_entry()
    local cmd = 'colorscheme ' .. selected[1]
    vim.cmd(cmd)
  end

  local all_colors = vim.fn.getcompletion("", "color")
  local opts = {
    --Modify the list of colors
    -- finder = finders.new_table {"gruvbox", "nordfox", "nightfox", "monokai", "tokyonight"},
    finder = finders.new_table(all_colors),
    sorter = sorters.get_generic_fuzzy_sorter({}),

    prompt_title = "Change Colorscheme: ( <C-n/p> <C-j/k> Enter )",

    attach_mappings = function(prompt_bufnr, map)
      map("i", "<CR>", enter)
      map("i", "<C-j>", next_color)
      map("i", "<C-k>", prev_color)
      return true
    end,

  }

  local colors = pickers.new(dropdown, opts)

  colors:find()
end

return M
