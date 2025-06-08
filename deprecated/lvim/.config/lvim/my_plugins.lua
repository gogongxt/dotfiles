local M = {}

local status, module = pcall(require, "my_config")

local image_enabled

if status then
  if module.image_enabled == nil then
    image_enabled = vim.fn.executable('luarocks') == 1
  else
    image_enabled = module.image_enabled
  end
else
  image_enabled = vim.fn.executable('luarocks') == 1
end

-- openai 软件是否使能，根据是否存在.openai_api_key文件判断
local gp_enabled
local gp_openai_key_file_path = os.getenv("HOME") .. "/.config/lvim/.openai_api_key"
local gp_proxy = "127.0.0.1:7890"
local f = io.open(gp_openai_key_file_path, "r")
if f ~= nil then
  io.close(f)
  gp_enabled = true
else
  gp_enabled = false
end


-- add my plugins
M.my_plugins = {
  {
    -- 和telescope相似但是固定的插件
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup({
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      })
    end,
    -- cmd = "TroubleToggle",
  },
  {
    -- 增强neovim中的quick fix
    -- better quick fix
    "kevinhwang91/nvim-bqf",
    config = function()
      require("bqf").setup({
        func_map = {
          pscrollup = "<C-u>",
          pscrolldown = "<C-d>",
        },
      })
    end,
  },
  {
    -- 大纲视图插件
    -- only works on https://github.com/universal-ctags/ctags
    "liuchengxu/vista.vim",
    config = function()
      vim.cmd([[
      let g:vista_sidebar_position = 'vertical topleft'
      let g:vista_default_executive = 'nvim_lsp'
      ]])
    end,

  },
  {
    -- telescope增强插件
    "nvim-telescope/telescope-live-grep-args.nvim",
  },
  {
    -- 光标跳转插件
    "phaazon/hop.nvim",
    branch = "v2", -- optional but strongly recommended
    config = function()
      -- you can configure Hop the way you like here; see :h hop-config
      require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
    end,
  },
  {
    -- 最好用的光标跳转插件
    "folke/flash.nvim",
    config = function()
      require("flash").setup({
        modes = {
          search = {
            enabled = false,
          },
          char = {
            enabled = false,
          },
        },
      })
    end,
  },
  {
    -- 增强调整各个窗口大小
    "simeji/winresizer",
  },
  {
    -- 高亮log结尾的文件
    'fei6409/log-highlight.nvim',
    config = function()
      require('log-highlight').setup {
        -- The file extensions.
        extension = 'log',
        -- The file names or the full file paths.
        filename = {
        },
        -- The glob patterns, e.g. `.*%.lg`, `/var/log/.*`.
        -- Note: `%.` is to match a literal dot (`.`) in a pattern in Lua, but most
        -- of the time `.` and `%.` here make no observable difference.
        pattern = {
        },
      }
    end,
  },
  {
    -- 括号对引号对快速修改插件
    "kylechui/nvim-surround",
    version = "*",
    config = function()
      require("nvim-surround").setup({
      })
    end,
  },
  {
    -- 高亮TODO等显示
    "folke/todo-comments.nvim",
    config = function()
      require("todo-comments").setup(
        {
          highlight = {
            multiline = false, -- enable multine todo comments
          },
        })
    end,
  },
  {
    -- 支持修改后自动保存文件
    "pocco81/auto-save.nvim",
    config = function()
      require("auto-save").setup()
    end,
  },
  {
    -- c/c++的增强lsp插件
    "p00f/clangd_extensions.nvim",
    dependencies = "mason-lspconfig.nvim", -- make sure to load after mason-lspconfig
    config = function()
      local provider = "clangd"
      local clangd_flags = {
        -- 在后台自动分析文件（基于complie_commands)
        "--compile-commands-dir=build",
        "--background-index",
        "--completion-style=detailed",
        -- 同时开启的任务数量
        "--all-scopes-completion=true",
        "--recovery-ast",
        "--suggest-missing-includes",
        -- 告诉clangd用那个clang进行编译，路径参考which clang++的路径
        "--query-driver=/usr/bin/clang++,/usr/bin/g++",
        "--clang-tidy",
        -- 全局补全（会自动补充头文件）
        "--all-scopes-completion",
        "--cross-file-rename",
        -- 更详细的补全内容
        "--completion-style=detailed",
        "--function-arg-placeholders=false",
        -- 补充头文件的形式
        "--header-insertion=never",
        -- pch优化的位置
        "--pch-storage=memory",
        "--offset-encoding=utf-16",
        "-j=16",
      }

      local custom_on_attach = function(client, bufnr)
        require("lvim.lsp").common_on_attach(client, bufnr)
        require("clangd_extensions.inlay_hints").setup_autocmd()
        require("clangd_extensions.inlay_hints").set_inlay_hints()
      end

      local custom_on_init = function(client, bufnr)
        require("lvim.lsp").common_on_init(client, bufnr)
        require("clangd_extensions.config").setup({})
        require("clangd_extensions.ast").init()
        vim.cmd([[
              command ClangdToggleInlayHints lua require('clangd_extensions.inlay_hints').toggle_inlay_hints()
              command -range ClangdAST lua require('clangd_extensions.ast').display_ast(<line1>, <line2>)
              command ClangdTypeHierarchy lua require('clangd_extensions.type_hierarchy').show_hierarchy()
              command ClangdSymbolInfo lua require('clangd_extensions.symbol_info').show_symbol_info()
              command -nargs=? -complete=customlist,s:memuse_compl ClangdMemoryUsage lua require('clangd_extensions.memory_usage').show_memory_usage('<args>' == 'expand_preamble')
              ]])
      end

      local opts = {
        cmd = { provider, unpack(clangd_flags) },
        on_attach = custom_on_attach,
        on_init = custom_on_init,
      }

      require("lvim.lsp.manager").setup("clangd", opts)
    end,
  },
  {
    -- neovim treesitter 增强
    -- TODO: 这里这个有一个超级无敌巨大bug，一定要限制版本
    -- Ref: https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/522
    -- 这个版本和nvim-treesitter的版本是有关联的
    -- 因为lunarvim会限制nvim-treesitter的版本，所有这里也需要限制
    -- 可能可以在lunarvim跨版本更新之后解除这个限制
    commit = "e1e670a86274d5cb681e475d4891ea1afe605ced",

    "nvim-treesitter/nvim-treesitter-textobjects",
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = false,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ["@parameter.outer"] = "v", -- charwise
              ["@function.outer"] = "V",  -- linewise
              ["@class.outer"] = "<c-v>", -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true of false
            include_surrounding_whitespace = true,
          },
          move = {
            enable = true,
            set_jumps = false, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]]"] = "@function.outer",
              -- ["]["] = "@function.outer",
            },
            goto_next_end = {
              ["]["] = "@function.outer",
              -- ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[["] = "@function.outer",
              -- ["[]"] = "@function.outer",
            },
            goto_previous_end = {
              ["[]"] = "@function.outer",
              -- ["[]"] = "@class.outer",
            },
          },
          lsp_interop = {
            enable = true,
            border = "none",
            peek_definition_code = {
              ["<leader>pf"] = "@function.outer",
              ["<leader>pF"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
  {
    -- 在telescope显示剪切板
    "AckslD/nvim-neoclip.lua",
    config = function()
      require("neoclip").setup({
        keys = {
          telescope = {
            i = {
              ["<C-j>"] = require("telescope.actions").cycle_history_next,
              ["<C-k>"] = require("telescope.actions").cycle_history_prev,
              ["<C-n>"] = require("telescope.actions").move_selection_next,
              ["<C-p>"] = require("telescope.actions").move_selection_previous,
              paste = "<CR>",
              delete = "<c-d>", -- delete an entry
              edit = "<c-e>",   -- edit an entry
              custom = {},
            },
            n = {
              ["<C-j>"] = require("telescope.actions").cycle_history_next,
              ["<C-k>"] = require("telescope.actions").cycle_history_prev,
              ["<C-n>"] = require("telescope.actions").move_selection_next,
              ["<C-p>"] = require("telescope.actions").move_selection_previous,
              paste = "<CR>",
              delete = "d", -- delete an entry
              edit = "e",   -- edit an entry
              custom = {},
            },
          },
        },
      })
      require("telescope").load_extension("neoclip")
    end,
  },
  {
    -- 增强lsp cmp补全
    "hrsh7th/cmp-nvim-lsp-signature-help",
  },
  {
    -- 支持回到上次推出neovim的位置
    "ethanholz/nvim-lastplace",
  },
  -- { -- json parser for dap launch.json
  --   -- NOTE: cargo required: https://rustup.rs/
  --   'Joakker/lua-json5',
  --   run = './install.sh'
  -- },
  {
    -- 增强dap 命令到telescope
    "nvim-telescope/telescope-dap.nvim",
    config = function()
      require("telescope").load_extension("dap")
    end,
  },
  {
    -- 支持快速片段化运行代码
    "michaelb/sniprun",
    build = "bash ./install.sh",
    config = function()
      require("sniprun").setup({
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
      })
    end,
  },
  {
    -- 增强颜色代码的颜色显示 #ff00ff
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end,
  },
  {
    -- 在有code action的地方显示灯泡
    "kosayoda/nvim-lightbulb",
    config = function()
      require("nvim-lightbulb").setup({
        autocmd = { enabled = true },
        -- LSP client names to ignore
        -- Example: {"sumneko_lua", "null-ls"}
        ignore = {},
        sign = {
          enabled = true,
          -- Priority of the gutter sign
          priority = 10,
        },
        float = {
          enabled = false,
          -- Text to show in the popup float
          text = "💡", --
          -- Available keys for window options:
          -- - height     of floating window
          -- - width      of floating window
          -- - wrap_at    character to wrap at for computing height
          -- - max_width  maximal width of floating window
          -- - max_height maximal height of floating window
          -- - pad_left   number of columns to pad contents at left
          -- - pad_right  number of columns to pad contents at right
          -- - pad_top    number of lines to pad contents at top
          -- - pad_bottom number of lines to pad contents at bottom
          -- - offset_x   x-axis offset of the floating window
          -- - offset_y   y-axis offset of the floating window
          -- - anchor     corner of float to place at the cursor (NW, NE, SW, SE)
          -- - winblend   transparency of the window (0-100)
          win_opts = {},
        },
        virtual_text = {
          enabled = true,
          -- Text to show at virtual text
          text = "💡", --
          -- highlight mode to use for virtual text (replace, combine, blend), see :help nvim_buf_set_extmark() for reference
          hl_mode = "replace",
        },
        status_text = {
          enabled = false,
          -- Text to provide when code actions are available
          text = "💡",
          -- Text to provide when no actions are available
          text_unavailable = "",
        },
      })
    end,
  },
  {
    -- 大纲视图显示
    "simrat39/symbols-outline.nvim",
    config = function()
      require("symbols-outline").setup({
        highlight_hovered_item = true,
        show_guides = true,
        auto_preview = false,
        position = "right",
        relative_width = true,
        width = 25,
        auto_close = false,
        show_numbers = false,
        show_relative_numbers = false,
        show_symbol_details = true,
        preview_bg_highlight = "Pmenu",
        autofold_depth = nil,
        auto_unfold_hover = true,
        fold_markers = { "", "" },
        wrap = false,
        keymaps = {
          -- These keymaps can be a string or a table for multiple keys
          close = { "<Esc>", "q" },
          goto_location = "<Cr>",
          focus_location = "o",
          hover_symbol = "<C-space>",
          toggle_preview = "K",
          rename_symbol = "r",
          code_actions = "a",
          fold = "h",
          unfold = "l",
          fold_all = "W",
          unfold_all = "E",
          fold_reset = "R",
        },
        lsp_blacklist = {},
        symbol_blacklist = {},
        symbols = {
          File = { icon = "", hl = "@text.uri" },
          Module = { icon = "", hl = "@namespace" },
          Namespace = { icon = "", hl = "@namespace" },
          Package = { icon = "", hl = "@namespace" },
          Class = { icon = "𝓒", hl = "@type" },
          Method = { icon = "ƒ", hl = "@method" },
          Property = { icon = "", hl = "@method" },
          Field = { icon = "", hl = "@field" },
          Constructor = { icon = "", hl = "@constructor" },
          Enum = { icon = "ℰ", hl = "@type" },
          Interface = { icon = "ﰮ", hl = "@type" },
          Function = { icon = "", hl = "@function" },
          Variable = { icon = "", hl = "@constant" },
          Constant = { icon = "", hl = "@constant" },
          String = { icon = "𝓐", hl = "@string" },
          Number = { icon = "#", hl = "@number" },
          Boolean = { icon = "⊨", hl = "@boolean" },
          Array = { icon = "", hl = "@constant" },
          Object = { icon = "⦿", hl = "@type" },
          Key = { icon = "🔐", hl = "@type" },
          Null = { icon = "NULL", hl = "@type" },
          EnumMember = { icon = "", hl = "@field" },
          Struct = { icon = "𝓢", hl = "@type" },
          Event = { icon = "🗲", hl = "@type" },
          Operator = { icon = "+", hl = "@operator" },
          TypeParameter = { icon = "𝙏", hl = "@parameter" },
          Component = { icon = "", hl = "@function" },
          Fragment = { icon = "", hl = "@constant" },
        },
      })
    end,
  },
  {
    -- 增强彩虹花括号显示
    -- NOTE: this plugin had been deprecated. Need move to new fork like https://github.com/HiPhish/nvim-ts-rainbow2
    "p00f/nvim-ts-rainbow",
  },
  {
    -- 增强在tmux中使用neovim
    "aserowy/tmux.nvim",
    config = function()
      require("tmux").setup({
        copy_sync = {
          -- enables copy sync. by default, all registers are synchronized.
          -- to control which registers are synced, see the `sync_*` options.
          enable = false,
          -- ignore specific tmux buffers e.g. buffer0 = true to ignore the
          -- first buffer or named_buffer_name = true to ignore a named tmux
          -- buffer with name named_buffer_name :)
          ignore_buffers = { empty = false },
          -- TMUX >= 3.2: all yanks (and deletes) will get redirected to system
          -- clipboard by tmux
          redirect_to_clipboard = false,
          -- offset controls where register sync starts
          -- e.g. offset 2 lets registers 0 and 1 untouched
          register_offset = 0,
          -- overwrites vim.g.clipboard to redirect * and + to the system
          -- clipboard using tmux. If you sync your system clipboard without tmux,
          -- disable this option!
          sync_clipboard = false,
          -- synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
          sync_registers = false,
          -- syncs deletes with tmux clipboard as well, it is adviced to
          -- do so. Nvim does not allow syncing registers 0 and 1 without
          -- overwriting the unnamed register. Thus, ddp would not be possible.
          sync_deletes = false,
          -- syncs the unnamed register with the first buffer entry from tmux.
          sync_unnamed = false,
        },
        navigation = {
          -- cycles to opposite pane while navigating into the border
          cycle_navigation = false,
          -- enables default keybindings (C-hjkl) for normal mode
          enable_default_keybindings = true,
          -- prevents unzoom tmux when navigating beyond vim border
          persist_zoom = false,
        },
        resize = {
          -- enables default keybindings (A-hjkl) for normal mode
          enable_default_keybindings = true,
          -- sets resize steps for x axis
          resize_step_x = 1,
          -- sets resize steps for y axis
          resize_step_y = 1,
        },
      })
    end,
  },
  -- { -- gxt_kt nvim-semantic-tokens :
  --   'theHamsta/nvim-semantic-tokens',
  --   config = function()
  --     require("nvim-semantic-tokens").setup {
  --       preset = "default",
  --       -- highlighters is a list of modules following the interface of nvim-semantic-tokens.table-highlighter or
  --       -- function with the signature: highlight_token(ctx, token, highlight) where
  --       --        ctx (as defined in :h lsp-handler)
  --       --        token  (as defined in :h vim.lsp.semantic_tokens.on_full())
  --       --        highlight (a helper function that you can call (also multiple times) with the determined highlight group(s) as the only parameter)
  --       highlighters = { require 'nvim-semantic-tokens.table-highlighter' }
  --     }
  --   end
  -- },
  {
    -- 缓冲区更新自动更新
    "djoshea/vim-autoread",
  },
  -- { -- gxt_kt far.vim : Search and substitute plugin
  --   'brooth/far.vim'
  -- },
  {
    -- 增强正则表达式搜索
    "jremmen/vim-ripgrep",
  },
  {
    -- 增强搜索和替换
    "windwp/nvim-spectre",
    config = function()
      require("spectre").setup({
        color_devicons = true,
        open_cmd       = 'vnew',
        live_update    = false, -- auto execute search again when you write to any file in vim
        line_sep_start = '┌-----------------------------------------',
        result_padding = '¦  ',
        line_sep       = '└-----------------------------------------',
        highlight      = { -- set with color group/ can use :highlight to see all color group
          ui = "String",
          search = "TodoBgTODO",
          replace = "TodoBgTEST"
        },
        mapping        = {
          ["send_to_qf"] = {
            map = "F",
            cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
            desc = "send all item to quickfix",
          },
          ["replace_cmd"] = {
            map = "C",
            cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
            desc = "input replace vim command",
          },
          ["show_option_menu"] = {
            map = "M",
            cmd = "<cmd>lua require('spectre').show_options()<CR>",
            desc = "show option",
          },
          ["run_current_replace"] = {
            map = "r",
            cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
            desc = "replace current line",
          },
          ["run_replace"] = {
            map = "R",
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = "replace all",
          },
          ["change_view_mode"] = {
            map = "<A-v>",
            cmd = "<cmd>lua require('spectre').change_view()<CR>",
            desc = "change result view mode",
          },
          ["toggle_live_update"] = {
            map = "U",
            cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
            desc = "update change when vim write file.",
          },
          ["toggle_ignore_case"] = {
            map = "I",
            cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
            desc = "toggle ignore case",
          },
          ["toggle_ignore_hidden"] = {
            map = "H",
            cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
            desc = "toggle search hidden",
          },
          ["resume_last_search"] = {
            map = "L",
            cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
            desc = "resume last search before close",
          },
          -- you can put your mapping here it only use normal mode
        },
      })
    end,
  },
  {
    -- 多光标支持
    "mg979/vim-visual-multi",
  },
  {
    -- 增强code action浮空显示
    "weilbith/nvim-code-action-menu",
    config = function()
      vim.g.code_action_menu_show_details = false
      vim.g.code_action_menu_show_diff = true
      vim.g.code_action_menu_show_action_kind = true
    end,
  },
  {
    -- 增强debug调试时在右侧显示变量值
    "theHamsta/nvim-dap-virtual-text",
    config = function()
      require("nvim-dap-virtual-text").setup({
        enabled = true,                     -- enable this plugin (the default)
        enabled_commands = true,            -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
        highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
        show_stop_reason = true,            -- show stop reason when stopped for exceptions
        commented = false,                  -- prefix virtual text with comment string
        only_first_definition = true,       -- only show virtual text at first definition (if there are multiple)
        all_references = false,             -- show virtual text on all all references of the variable (not only definitions)
        --- A callback that determines how a variable is displayed or whether it should be omitted
        --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
        --- @param buf number
        --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
        --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
        --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
        display_callback = function(variable, _buf, _stackframe, _node)
          return variable.name .. " = " .. variable.value
        end,

        -- experimental features:
        virt_text_pos = "eol",   -- position of virtual text, see `:h nvim_buf_set_extmark()`
        all_frames = false,      -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
        virt_lines = false,      -- show virtual lines instead of virtual text (will flicker!)
        virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
        -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
      })
    end,
  },
  {
    -- 支持当前buffer最大化
    "szw/vim-maximizer",
  },
  {
    -- 可以再浏览器中预览markdown文件
    "iamcco/markdown-preview.nvim",
    config = function()
      vim.fn["mkdp#util#install"]()
      vim.g.mkdp_auto_close = 0 -- not close when changing buffer
    end,
  },
  {
    -- 增强代码块 {} 指示显示
    "shellRaining/hlchunk.nvim",
    config = function()
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { pattern = "*", command = "EnableHL" })
      require("hlchunk").setup({
        chunk = {
          enable = true,
          use_treesitter = false,
          notify = true, -- notify if some situation(like disable chunk mod double time)
          exclude_filetypes = {
            aerial = true,
            dashboard = true,
          },
          support_filetypes = {
            "*.lua",
            "*.js",
          },
          chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            right_arrow = ">",
          },
          style = {
            { fg = "#CB8764" },
          },
        },
        indent = {
          enable = true, --
          -- chars = { "│", "¦", "┆", "┊" },
          chars = { "▏" },
          -- chars = { " ", " ", " ", " " },
          use_treesitter = false,
          style = {
            -- { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") }
            { fg = "#51576e" }
          },
        },
        line_num = {
          enable = false,
          use_treesitter = true,
          style = "#806d9c",
        },
        blank = {
          enable = false,
          chars = {
            "․",
          },
          style = {
            vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui"),
          },
        },
      })
    end,
  },
  -- {
  --   -- 增强缩进栏彩色显示
  --   'lukas-reineke/indent-blankline.nvim',
  --   config = function()
  --     vim.opt.termguicolors = true
  --     vim.cmd [[highlight IndentBlanklineIndent1 guifg=#E06C75 gui=nocombine]]
  --     vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E5C07B gui=nocombine]]
  --     vim.cmd [[highlight IndentBlanklineIndent3 guifg=#98C379 gui=nocombine]]
  --     vim.cmd [[highlight IndentBlanklineIndent4 guifg=#56B6C2 gui=nocombine]]
  --     vim.cmd [[highlight IndentBlanklineIndent5 guifg=#61AFEF gui=nocombine]]
  --     vim.cmd [[highlight IndentBlanklineIndent6 guifg=#C678DD gui=nocombine]]

  --     vim.opt.list = true
  --     vim.opt.listchars:append "space:⋅"
  --     -- vim.opt.listchars:append "eol:↴"

  --     require("indent_blankline").setup {
  --       space_char_blankline = " ",
  --       char_highlight_list = {
  --         "IndentBlanklineIndent1",
  --         "IndentBlanklineIndent2",
  --         "IndentBlanklineIndent3",
  --         "IndentBlanklineIndent4",
  --         "IndentBlanklineIndent5",
  --         "IndentBlanklineIndent6",
  --       },
  --     }
  --   end
  -- },
  {
    -- 打的断点可以保留下来，推出neovim再打开还在
    "Weissle/persistent-breakpoints.nvim",
    config = function()
      require("persistent-breakpoints").setup({
        save_dir = vim.fn.stdpath("data") .. "/nvim_checkpoints", -- $HOME/.local/share/lvim/nvim_checkpoints/*
        load_breakpoints_event = { "BufReadPost" },
      })
    end,
  },
  {
    -- 只高亮光标所在代码块
    "folke/twilight.nvim",
    opts = {
      context = 3,
    },
  },
  {
    -- 增强折叠显示
    'kevinhwang91/nvim-ufo',
    dependencies = 'kevinhwang91/promise-async',
    config = function()
      vim.o.foldcolumn = '0' -- '0' is not bad
      vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

      -- Option 2: nvim lsp as LSP client
      -- Tell the server the capability of foldingRange,
      -- Neovim hasn't added foldingRange to default capabilities, users must add it manually
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true
      }
      local language_servers = require("lspconfig").util.available_servers() -- or list servers manually like {'gopls', 'clangd'}
      for _, ls in ipairs(language_servers) do
        -- NOTE: gxt_kt: Must change lspconfig to lvim.lsp.manager
        -- Otherwise will make lsp server start failure
        require('lvim.lsp.manager').setup(ls, {
          capabilities = capabilities
          -- you can add other fields for setting up lsp server in this table
        })
        -- require('lspconfig')[ls].setup({
        --   capabilities = capabilities
        --   -- you can add other fields for setting up lsp server in this table
        -- })
      end
      -- require('ufo').setup()
      --
      --
      --
      local handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, 'MoreMsg' })
        return newVirtText
      end

      -- global handler
      -- `handler` is the 2nd parameter of `setFoldVirtTextHandler`,
      -- check out `./lua/ufo.lua` and search `setFoldVirtTextHandler` for detail.
      require('ufo').setup({
        fold_virt_text_handler = handler
      })
    end,
  },
  -- {
  --   "LintaoAmons/easy-commands.nvim",
  --   config = function()
  --     require("easy-commands").Setup({
  --       disabledCommands = { "CopyFilename", "FormatCode" }, -- You can disable the commands you don't want
  --       myCommands = { -- It always welcome to send me back your good commands and usecases
  --         ["MyCommand"] = "lua vim.print('easy command user command')", -- You can add your own commands, commands can be string | function | table
  --         ["EasyCommand"] = "lua vim.print('Over write easy-command builtin command')", -- You can overwrite the current implementation
  --         ["CopyCdCommand"] = function()
  --           local editor = require("easy-commands.impl.util.editor") -- You can use the utils provided by the plugin to build your own command
  --           local cmd = "cd " .. editor.get_buf_abs_dir_path()
  --           vim.print(cmd)
  --           require("easy-commands.impl.util.base.sys").CopyToSystemClipboard(cmd)
  --         end,
  --       },
  --       ["RunSelectedAndOutputWithPrePostFix"] = { -- Each Command may have defferent config options, check out the commands to find more options.
  --         prefix = "```lua",
  --         postfix = "```",
  --       },
  --     })
  --   end
  -- }
  {
    -- 定义自己的状态栏，比如让git标识显示在行号右侧
    "luukvbaal/statuscol.nvim",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        setopt = true, -- Whether to set the 'statuscolumn' option, may be set to false for those who
        -- want to use the click handlers in their own 'statuscolumn': _G.Sc[SFL]a().
        -- Although I recommend just using the segments field below to build your
        -- statuscolumn to benefit from the performance optimizations in this plugin.
        -- builtin.lnumfunc number string options
        thousands = false,  -- or line number thousands separator string ("." / ",")
        relculright = true, -- whether to right-align the cursor line number with 'relativenumber' set
        -- Builtin 'statuscolumn' options
        ft_ignore = nil,    -- lua table with filetypes for which 'statuscolumn' will be unset
        bt_ignore = nil,    -- lua table with 'buftype' values for which 'statuscolumn' will be unset
        -- Default segments (fold -> sign -> line number + separator), explained below
        segments = {
          -- { text = { builtin.foldfunc }, click = "v:lua.ScSa" },
          {
            sign = {
              name = { ".*" },
              namespace = { ".*" },
              max_width = 2,
              colwidth = 2,
              auto = false,
            },
            condition = { true, builtin.not_empty },
            click = "v:lua.ScLa",
          },
          -- {
          --   sign = {
          --     name = { "Diagnostic" },
          --     max_width = 1,
          --     colwidth = 1,
          --     auto = false,
          --   },
          --   click = "v:lua.ScLa",
          -- },
          {
            text = { builtin.lnumfunc, " " },
            -- condition = { true, builtin.not_empty },
            click = "v:lua.ScLa",
          },
          {
            -- Ref: https://github.com/luukvbaal/statuscol.nvim/issues/71
            sign = {
              name = { "GitSign" },
              namespace = { "gitsign" },
              max_width = 1,
              colwidth = 1,
              auto = false,
            },
            -- condition = { true, builtin.not_empty },
            click = "v:lua.ScLa",
          },
        },
        clickmod = "c",   -- modifier used for certain actions in the builtin clickhandlers:
        -- "a" for Alt, "c" for Ctrl and "m" for Meta.
        clickhandlers = { -- builtin click handlers
          Lnum                    = builtin.lnum_click,
          FoldClose               = builtin.foldclose_click,
          FoldOpen                = builtin.foldopen_click,
          FoldOther               = builtin.foldother_click,
          DapBreakpointRejected   = builtin.toggle_breakpoint,
          DapBreakpoint           = builtin.toggle_breakpoint,
          DapBreakpointCondition  = builtin.toggle_breakpoint,
          DiagnosticSignError     = builtin.diagnostic_click,
          DiagnosticSignHint      = builtin.diagnostic_click,
          DiagnosticSignInfo      = builtin.diagnostic_click,
          DiagnosticSignWarn      = builtin.diagnostic_click,
          GitSignsTopdelete       = builtin.gitsigns_click,
          GitSignsUntracked       = builtin.gitsigns_click,
          GitSignsAdd             = builtin.gitsigns_click,
          GitSignsChange          = builtin.gitsigns_click,
          GitSignsChangedelete    = builtin.gitsigns_click,
          GitSignsDelete          = builtin.gitsigns_click,
          gitsigns_extmark_signs_ = builtin.gitsigns_click,
        },
      })
    end,
  },
  {
    -- 增强笔记文件显示，markdown, orgmode, neorg
    -- show latex on markdown file can use plugin "jbyuki/nabla.nvim"
    'lukas-reineke/headlines.nvim',
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("headlines").setup()
    end,
  },
  {
    -- visual自动选择，按enter增加，backspace减少
    "sustech-data/wildfire.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("wildfire").setup()
    end,
  },
  {
    -- 增强/高亮搜索（在右侧显示检测到多少个，当前在第几个）
    'kevinhwang91/nvim-hlslens',
    config = function()
      require('hlslens').setup({
        calm_down = false,
        nearest_only = true,
        nearest_float_when = 'never'
      })
      local kopts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap('n', 'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
    end
  },
  {
    -- 书签插件
    'tomasky/bookmarks.nvim',
    config = function()
      require('bookmarks').setup({
        -- sign_priority = 8,  --set bookmark sign priority to cover other sign
        save_file = vim.fn.expand "$HOME/.bookmarks", -- bookmarks save file path
        keywords = {
          ["@t"] = "☑️ ", -- mark annotation startswith @t ,signs this icon as `Todo`
          ["@w"] = "⚠️ ", -- mark annotation startswith @w ,signs this icon as `Warn`
          ["@f"] = "⛏ ", -- mark annotation startswith @f ,signs this icon as `Fix`
          ["@n"] = " ", -- mark annotation startswith @n ,signs this icon as `Note`
        },
        on_attach = function(bufnr)
          local bm = require "bookmarks"
          local map = vim.keymap.set
          map("n", "mm", bm.bookmark_toggle) -- add or remove bookmark at current line
          map("n", "mi", bm.bookmark_ann)    -- add or edit mark annotation at current line
          map("n", "mc", bm.bookmark_clean)  -- clean all marks in local buffer
          map("n", "mn", bm.bookmark_next)   -- jump to next mark in local buffer
          map("n", "mp", bm.bookmark_prev)   -- jump to previous mark in local buffer
          map("n", "ml", bm.bookmark_list)   -- show marked file list in quickfix window
        end
      })
    end
  },
  {
    -- 在neovim中刷leetcode
    enabled = true,

    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim", -- required by telescope
      "MunifTanjim/nui.nvim",

      -- optional
      "nvim-treesitter/nvim-treesitter",
      "rcarriga/nvim-notify",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      -- configuration goes here
      --
      ---@type lc.lang
      lang = "cpp",
      cn = { -- leetcode.cn
        enabled = true, ---@type boolean
        translator = false, ---@type boolean
        translate_problems = true, ---@type boolean
      },
      injector = { ---@type table<lc.lang, lc.inject>
        ["cpp"] = {
          before = {
            "#include <bits/stdc++.h>",
            "",
            '#include "/home/gxt_kt/Projects/debugstream/debugstream.hpp"',
            "using namespace std;"
          },
          after = {
            "int main() {",
            '  std::cout << "hello ";',
            '  std::cout << "world!" << std::endl;',
            '  Solution solution;',
            "}"
          },
        },
        ["java"] = {
          before = "import java.util.*;",
        },
      },
      keys = {
        toggle = { "q", "<Esc>" }, ---@type string|string[]
        confirm = { "<CR>" }, ---@type string|string[]

        reset_testcases = "r", ---@type string
        use_testcase = "U", ---@type string
        focus_testcases = "<C-h>", ---@type string
        focus_result = "<C-l>", ---@type string
      },

      ---@type boolean
      image_support = image_enabled, -- setting this to `true` will disable question description wrap
    },
  },
  {
    -- 在neovim中显示图片
    enabled = image_enabled,

    "3rd/image.nvim",
    config = function()
      -- -- Example for configuring Neovim to load user-installed installed Lua rocks:
      -- at ~ exec $luarocks --local --lua-version=5.1 install magick
      package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
      package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"
      -- default config
      require("image").setup({
        backend = "ueberzug",
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
        window_overlap_clear_enabled = false,                                     -- toggles images when windows are overlapped
        window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        editor_only_render_when_focused = false,                                  -- auto show/hide images when the editor gains/looses focus
        tmux_show_only_in_active_window = true,                                   -- auto show/hide images in the correct Tmux window (needs visual-activity off)
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" }, -- render image files as images when opened
      })
    end
  },
  {
    -- git 增强插件
    "sindrets/diffview.nvim"
  },
  {
    -- git 增强插件
    "FabijanZulj/blame.nvim",
    config = function()
      require('blame').setup({
        width = 45,
        merge_consecutive = true
      })
    end
  },
  {
    -- 切换python虚拟环境（conda）
    "AckslD/swenv.nvim",
  },
  {
    -- chatgpt openai插件
    enabled = gp_enabled,

    "robitx/gp.nvim",
    config = function()
      -- require("gp").setup()
      require("gp").setup({
        openai_api_key = { "cat", os.getenv("HOME") .. "/.config/lvim/.openai_api_key" },
        curl_params = { "--proxy", gp_proxy },
        -- openai_api_key = os.getenv("OPENAI_API_KEY"),
      })
      -- or setup with your own config (see Install > Configuration in Readme)
      -- require("gp").setup(config)

      -- shortcuts might be setup here (see Usage > Shortcuts in Readme)
    end,
  },
  {
    -- rust增强插件，替换掉 rust-tools.nvim
    'mrcjkb/rustaceanvim',
    version = '^4', -- Recommended
    lazy = false,   -- This plugin is already lazy
  },
  -- { -- gxt_kt vim-tmux-clipboard : vim tmux clipboard
  --   'roxma/vim-tmux-clipboard',
  -- },
  --
  --
}

return M
