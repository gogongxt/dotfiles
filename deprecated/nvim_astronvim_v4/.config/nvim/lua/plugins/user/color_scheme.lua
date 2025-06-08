-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- themes: https://vimcolorschemes.com/

return {
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      -- change colorscheme
      colorscheme = "catppuccin",
      -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
      highlights = {
        init = { -- this table overrides highlights in all themes
          -- Normal = { bg = "#000000" },
          Folded = { bg = nil }, -- 配置折叠代码块背景色为空（默认是有一个蒙版一样的）
        },
        astrodark = { -- a table of overrides/changes when applying the astrotheme theme
          -- Normal = { bg = "#000000" },
        },
      },
      -- Icons can be configured throughout the interface
      icons = {
        -- configure the loading of the lsp in the status line
        LSPLoading1 = "⠋",
        LSPLoading2 = "⠙",
        LSPLoading3 = "⠹",
        LSPLoading4 = "⠸",
        LSPLoading5 = "⠼",
        LSPLoading6 = "⠴",
        LSPLoading7 = "⠦",
        LSPLoading8 = "⠧",
        LSPLoading9 = "⠇",
        LSPLoading10 = "⠏",
      },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup {
        flavour = "frappe", -- latte, frappe, macchiato, mocha
      }
    end,
  },
  {
    "EdenEast/nightfox.nvim",
  },
  {
    "sainnhe/everforest",
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
    init = function() vim.g.material_style = "palenight" end,
    config = function()
      require("material").setup {
        contrast = {
          terminal = false, -- Enable contrast for the built-in terminal
          sidebars = false, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
          floating_windows = false, -- Enable contrast for floating windows
          cursor_line = false, -- Enable darker background for the cursor line
          non_current_windows = false, -- Enable darker background for non-current windows
          filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
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
          "coc",
          "colorful-winsep",
          "dap",
          "dashboard",
          "eyeliner",

          "fidget",
          "flash",
          "gitsigns",
          "harpoon",
          "hop",
          "illuminate",
          "indent-blankline",
          "lspsaga",
          "mini",
          "neogit",
          "neotest",
          "neo-tree",
          "neorg",
          "noice",
          "nvim-cmp",
          "nvim-navic",
          "nvim-tree",
          "nvim-web-devicons",
          "rainbow-delimiters",
          "sneak",
          "telescope",
          "trouble",
          "which-key",
          "nvim-notify",
        },
        disable = {
          colored_cursor = true, -- Disable the colored cursor
          borders = false, -- Disable borders between verticaly split windows
          background = false, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
          term_colors = false, -- Prevent the theme from setting terminal colors
          eob_lines = false, -- Hide the end-of-buffer lines
        },
        high_visibility = {
          lighter = false, -- Enable higher contrast text for lighter style
          darker = false, -- Enable higher contrast text for darker style
        },
        lualine_style = "default", -- Lualine style ( can be 'stealth' or 'default' )
        async_loading = true, -- Load parts of the theme asyncronously for faster startup (turned on by default)
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
      }
    end,
  },

  -- CycleColors
  -- Ref: https://neovim.discourse.group/t/creating-a-color-picker-using-telescope/1986
  -- In order to mapp this function you have to map the command below:
  -- :lua require('${file}').choose_colors()
  ChooseColors = function()
    local actions = require "telescope.actions"
    local actions_state = require "telescope.actions.state"
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local sorters = require "telescope.sorters"
    local dropdown = require("telescope.themes").get_dropdown()

    local function enter(prompt_bufnr)
      local selected = actions_state.get_selected_entry()
      local cmd = "colorscheme " .. selected[1]
      vim.cmd(cmd)
      actions.close(prompt_bufnr)
    end

    local function move_next(prompt_bufnr) actions.move_selection_next(prompt_bufnr) end
    local function move_prev(prompt_bufnr) actions.move_selection_previous(prompt_bufnr) end

    local function next_color(prompt_bufnr)
      move_next(prompt_bufnr)
      local selected = actions_state.get_selected_entry()
      local cmd = "colorscheme " .. selected[1]
      vim.cmd(cmd)
    end
    local function prev_color(prompt_bufnr)
      move_prev(prompt_bufnr)
      local selected = actions_state.get_selected_entry()
      local cmd = "colorscheme " .. selected[1]
      vim.cmd(cmd)
    end

    local all_colors = vim.fn.getcompletion("", "color")

    -- 获取当前的颜色主题
    local current_color = vim.g.colors_name or vim.o.background or ""
    -- 设定默认选择的颜色
    local default_selection = nil
    for i, color in ipairs(all_colors) do
      if color == current_color then
        default_selection = i
        break
      end
    end

    local opts = {
      --Modify the list of colors
      -- finder = finders.new_table {"gruvbox", "nordfox", "nightfox", "monokai", "tokyonight"},
      finder = finders.new_table(all_colors),
      sorter = sorters.get_generic_fuzzy_sorter {},

      prompt_title = "Change Colorscheme: ( <C-n/p> <C-j/k> Enter )",

      -- 设置默认选择当前的主题
      default_selection_index = default_selection,

      attach_mappings = function(prompt_bufnr, map)
        map("i", "<CR>", enter)
        map("i", "<C-n>", move_next)
        map("i", "<C-p>", move_prev)
        map("i", "<C-j>", next_color)
        map("i", "<C-k>", prev_color)
        return true
      end,
    }

    local colors = pickers.new(dropdown, opts)

    colors:find()
  end,
}
