-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      -- Configure core features of AstroNvim
      features = {
        large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
        autopairs = true, -- enable autopairs at start
        cmp = true, -- enable completion at start
        diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
        highlighturl = true, -- highlight URLs at start
        notifications = true, -- enable notifications at start
      },
      -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
      diagnostics = {
        virtual_text = true,
        underline = true,
      },
      -- passed to `vim.filetype.add`
      filetypes = {
        -- see `:h vim.filetype.add` for usage
        extension = {
          foo = "fooscript",
        },
        filename = {
          [".foorc"] = "fooscript",
        },
        pattern = {
          [".*/etc/foo/.*"] = "fooscript",
        },
      },
      -- vim options can be configured here
      options = {
        opt = { -- vim.opt.<key>
          relativenumber = true, -- sets vim.opt.relativenumber
          number = true, -- sets vim.opt.number
          spell = false, -- sets vim.opt.spell
          signcolumn = "yes", -- sets vim.opt.signcolumn to yes
          -- signcolumn = "auto", -- sets vim.opt.signcolumn to auto
          wrap = false, -- sets vim.opt.wrap
        },
        g = { -- vim.g.<key>
          -- configure global vim variables (vim.g)
          -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
          -- This can be found in the `lua/lazy_setup.lua` file
        },
      },
      -- Mappings can be configured through AstroCore as well.
      -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
      mappings = {
        -- first key is the mode
        n = {
          -- second key is the lefthand side of the map
          -- mappings seen under group name "Buffer"
          ["<Leader>bd"] = {
            function()
              require("astroui.status.heirline").buffer_picker(
                function(bufnr) require("astrocore.buffer").close(bufnr) end
              )
            end,
            desc = "Close buffer from tabline",
          },

          -- tables with just a `desc` key will be registered with which-key if it's installed
          -- this is useful for naming menus
          -- ["<Leader>b"] = { desc = "Buffers" },

          -- setting a mapping to false will disable it
          -- ["<C-S>"] = false,
          ["<Leader>e"] = false, -- disable default Neo-tree toggle mapping

          L = {
            function() require("astrocore.buffer").nav(vim.v.count1) end,
            desc = "Next buffer",
          },
          H = {
            function() require("astrocore.buffer").nav(-vim.v.count1) end,
            desc = "Previous buffer",
          },
          ["<Leader>H"] = {
            function() require("astrocore.buffer").move(-vim.v.count1) end,
            desc = "Move buffer tab left",
          },
          ["<Leader>L"] = {
            function() require("astrocore.buffer").move(vim.v.count1) end,
            desc = "Move buffer tab right",
          },

          -- universal
          ["<Leader>h"] = { "<cmd>nohl<cr>", desc = "<cmd>nohl" },
          ["q"] = { "<Nop>", desc = "disable micro" },

          -- save file
          ["<leader>w"] = { "<cmd>w<cr>", desc = "Save File" },
          -- ["<C-s>"] = { "<cmd>w<cr>", desc = "Save File" },
          ["<Leader>W"] = {
            function() require("user.my_funcs.sudo_write").sudo_write() end,
            desc = "Write with root",
          },

          -- run cmd
          ["<Leader>R"] = {
            "<cmd>lua require('user.my_funcs.execute_and_print_cmd').execute_and_print_cmd()<cr>",
            desc = "Run cmd",
            noremap = true,
            silent = true,
          },

          -- go to file
          ["gf"] = {
            "<cmd>lua require('user.my_funcs.goto_file').extract_file_info()<cr>",
            desc = "Goto file",
            noremap = true,
            silent = true,
          },

          -- delete empty lines
          ["<Leader>lc"] = {
            "<cmd>lua require('user.my_funcs.delete_empty_lines').delete_empty_lines()<CR>",
            desc = "Delete Empty Lines",
            noremap = true,
            silent = true,
          },

          -- change to tab
          -- TODO: add tabs
          -- ["<Leader>t"] = { name = "Tabs" },
          -- ["<Leader>t<C-n>"] = { "<cmd>tabnew<cr>", desc = "New tab", noremap = true, silent = true },
          -- ["<Leader>tn"] = { "<cmd>tabnext<cr>", desc = "New tab", noremap = true, silent = true },
          -- ["<Leader>tp"] = { "<cmd>tabprevious<cr>", desc = "New tab", noremap = true, silent = true },
        },
        v = {
          -- This will not change the clipboard content in V mode
          ["p"] = { '"_dP', desc = "", noremap = true, silent = true },

          -- go to file
          ["gf"] = {
            "<cmd>lua require('user.my_funcs.goto_file').extract_file_info(require('user.my_funcs').get_text('v'))<cr>",
            desc = "Goto file",
          },

          -- delete empty lines
          ["<Leader>lc"] = {
            "<cmd>lua require('user.my_funcs.delete_empty_lines').delete_empty_lines('v')<CR>",
            desc = "Delete Empty Lines",
            noremap = true,
            silent = true,
          },
        },
      },
      -- v6: Treesitter configuration moved to AstroCore
      treesitter = {
        ensure_installed = {
          "lua",
          "vim",
          "css",
          "html",
          "javascript",
          "latex",
          "scss",
          "svelte",
          "tsx",
          "typst",
          "vue",
        },
        highlight = true,
      },
    },
  },
}
