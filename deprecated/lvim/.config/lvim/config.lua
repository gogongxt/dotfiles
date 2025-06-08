-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = false


-- Add scripts find path
local home = os.getenv("HOME")
package.path = home .. "/.config/lvim/?.lua" -- $HOME/.config/lvim/*.lua
-- define lvim.plugins
require('my_plugins')
require('my_theme')

lvim.plugins = {}
-- add theme plugins
for _, item in ipairs(require('my_theme').plugins_theme) do
  table.insert(lvim.plugins, item)
end
-- add my plugins
for _, item in ipairs(require('my_plugins').my_plugins) do
  table.insert(lvim.plugins, item)
end


-- 添加snippets内容
-- Ref: https://www.lunarvim.org/docs/configuration/language-features/custom-snippets
-- Ref: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#vs-code
-- require("luasnip.loaders.from_vscode").load({paths = "./snippets"})


--  options fold from treesitter
do
  vim.opt.foldlevel = 99
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
end
vim.opt.relativenumber = true -- set relative numbered lines
-- vim.opt.colorcolumn = "80" -- a line at 80 column postion -- 80 for google c++ style

-- vim.opt.signcolumn = "yes:2"

lvim.leader = ","
lvim.keys.insert_mode["jk"] = "<Esc>"
lvim.keys.normal_mode["<leader>\\"] = "<C-w>v"
lvim.keys.normal_mode["<leader><BS>"] = "<C-w>v"
lvim.keys.normal_mode["<leader>-"] = "<C-w>s"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<S-h>"] = false -- default combine to ^
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-l>"] = false -- default combine to $
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
-- lvim.keys.normal_mode["H"] = "^"
-- lvim.keys.normal_mode["L"] = "$"
-- lvim.keys.normal_mode["Q"] = "q"
lvim.keys.normal_mode["<leader>h"] = ":nohl<cr>"
lvim.keys.normal_mode["<leader>H"] = ":Twilight<cr>"
lvim.keys.normal_mode["<leader>W"] = ":set wrap!<cr>"
lvim.keys.normal_mode["<leader>S"] = ":set invspell<cr>" -- https://vimtricks.com/p/vim-spell-check/
lvim.keys.normal_mode["<leader>n"] = ":set relativenumber!<cr>"
lvim.keys.normal_mode["<leader>j"] = ":ClangdSwitchSourceHeader<cr>"
lvim.builtin.which_key.mappings.o = nil
lvim.builtin.which_key.mappings["o"] = {
  name = "+outline",
  ["s"] = { "<cmd>SymbolsOutline <cr>", "Outline" },
  ["<tab>"] = { "<cmd>Vista!! <cr>", "Vista" },
  ["h"] = { "<cmd>ClangdTypeHierarchy<cr>", "Hierarchy" },
}
-- This will not change the clipboard content in V mode
lvim.keys.visual_mode["p"] = '"_dP'
lvim.keys.normal_mode["<leader>q"] = ":bd<cr>"
lvim.keys.normal_mode["<leader>Q"] = ":bd!<cr>"
lvim.keys.normal_mode["<leader>c"] = ":q<cr>"
-- 禁用vim中的宏
lvim.keys.normal_mode["q"] = "<Nop>"
-- 搜索时把结果置于中间并打开折叠
lvim.keys.normal_mode["n"] = "nzzzv"
lvim.keys.normal_mode["N"] = "Nzzzv"
-- 让下一行加到当前行末尾，删掉所有缩进，并加一个空格
lvim.keys.normal_mode["J"] = "mzJ`z"


lvim.keys.normal_mode["<leader>Db"] = { ":lua require('my_funcs').DebugBuffer(vim.api.nvim_get_current_buf())<CR>" }
lvim.keys.normal_mode["<leader>DB"] = { ":lua require('my_funcs').DebugAllBuffers()<CR>" }

-- 支持%跳转"<>"
vim.opt.matchpairs:append("<:>")

-- 将选定的行移动到上/下方一行，并缩进。
-- lvim.keys.visual_mode["J"] = ":m '>+1<CR>gv=gv"
-- lvim.keys.visual_mode["K"] = ":m '<-2<CR>gv=gv"

-- maximal keymap
-- toggle split window maximization
lvim.keys.normal_mode["<leader>z"] = ":MaximizerToggle<CR>"

-- Markdown-preview keymap
lvim.keys.normal_mode["<leader>md"] = ":MarkdownPreview<CR>"

-- cmp配置修改 支持table替换，enter插入
-- lvim.builtin.cmp.confirm_opts.select=true
lvim.builtin.cmp.completion = { -- 修改默认就选择第一条
  completeopt = "menu,menuone,noinsert",
}
-- 修改tab为替换，<CR>默认就是直接插入了
lvim.builtin.cmp.mapping["<C-Enter>"] = require("cmp").mapping(require('cmp').mapping.complete(), { "i", "c" })
lvim.builtin.cmp.mapping["<Tab>"] = require("cmp").mapping({
  i = require("cmp").mapping.confirm({ behavior = require("cmp").ConfirmBehavior.Replace, select = true }),
  c = function(fallback)
    if require("cmp").visible() then
      require("cmp").confirm({ behavior = require("cmp").ConfirmBehavior.Replace, select = true })
    else
      fallback()
    end
  end,
})

-- colortheme choose color
lvim.keys.normal_mode["<leader>C"] = { ":lua require('my_theme').choose_colors()<CR>" }

-- colortheme choose color
lvim.keys.normal_mode["<leader><C-s>"] = { ":lua require('my_funcs').sudo_write()<CR>" }

-- lsp
lvim.keys.normal_mode["<leader>in"] = ":lua vim.lsp.buf.incoming_calls()<cr>"
lvim.keys.visual_mode["<leader>lf"] = { ":lua require('my_funcs').range_formatting()<CR>", desc = "Range Format Code" }
lvim.builtin.which_key.mappings["la"] = { ":CodeActionMenu<CR>", "My code action" }

-- run bash cmd and print
lvim.keys.visual_mode["<leader>R"] = ":lua require('my_funcs').execute_and_print_cmd()<CR>"
lvim.keys.normal_mode["<leader>R"] = "V:lua require('my_funcs').execute_and_print_cmd()<CR>"

-- run go to file
lvim.keys.normal_mode["gf"] = ":lua require('my_funcs').extract_file_info()<CR>"
lvim.keys.visual_mode["gf"] = ":lua require('my_funcs').extract_file_info(require('my_funcs').get_text('v'))<CR>"

-- change default lazygit to gitui
-- https://github.com/LunarVim/LunarVim/issues/4380
-- lvim.builtin.which_key.mappings["gg"] = {}
lvim.builtin.which_key.mappings.g.g = { ":lua require('my_funcs').git_gitui_toggle()<CR>", "gitui" }
-- lvim.builtin.which_key.mappings["gg"] = { ":lua require('my_funcs').git_gitui_toggle()<CR>", "gitui" }
-- add git Blame function
lvim.builtin.which_key.mappings.g.B = { "<cmd>:ToggleBlame<CR>", "Git Blame" }

-- leetcode
lvim.builtin.which_key.mappings.L = nil
lvim.builtin.which_key.mappings["Ll"] = { "<cmd>:Leet list<CR>", "Leet list" }
lvim.builtin.which_key.mappings["Lm"] = { "<cmd>:Leet menu<CR>", "Leet menui" }
lvim.builtin.which_key.mappings["Lt"] = { "<cmd>:Leet tabs<CR>", "Leet tabs" }
lvim.builtin.which_key.mappings["Lr"] = { "<cmd>:Leet run<CR>", "Leet run" }
-- lvim.builtin.which_key.mappings["Lt"] = { "<cmd>:Leet test<CR>", "Leet test" }
lvim.builtin.which_key.mappings["Ls"] = { "<cmd>:Leet submit<CR>", "Leet submit" }
lvim.builtin.which_key.mappings["Lc"] = { "<cmd>:Leet cache<CR>", "Leet cache" }
lvim.builtin.which_key.mappings["Li"] = { "<cmd>:Leet info<CR>", "Leet info" }
lvim.builtin.which_key.mappings["L<tab>"] = { "<cmd>:Leet desc<CR>", "Leet desc" }
lvim.builtin.which_key.mappings["Lv"] = { "<cmd>:Leet console<CR>", "Leet console" }


lvim.builtin.which_key.mappings.G = nil
lvim.builtin.which_key.mappings["Gn"] = { "<cmd>:GpChatNew tabnew<CR>", "Gpt Newtab" }
lvim.builtin.which_key.mappings["Gv"] = { "<cmd>:GpChatNew vsplit<CR>", "Gpt Usplit" }
lvim.builtin.which_key.mappings["Gs"] = { "<cmd>:GpChatNew split<CR>", "Gpt Split" }
lvim.builtin.which_key.mappings["Gp"] = { "<cmd>:GpChatNew popup<CR>", "Gpt Popup" }
lvim.builtin.which_key.mappings["Gf"] = { "<cmd>:GpChatFinder<CR>", "Gpt Find" }
lvim.builtin.which_key.mappings["GS"] = { "<cmd>:GpStop<CR>", "Gpt Stop" }
lvim.builtin.which_key.mappings["Gt"] = { "<cmd>:GpChatToggle<CR>", "Gpt Toggle" }


-- spectre
-- open in current file
lvim.keys.normal_mode["sf"] = ":lua require('spectre').open_file_search()<CR>"
-- open in whole ws
lvim.keys.normal_mode["sF"] = ":lua require('spectre').open()<CR>"
vim.keymap.set('n', 'sw', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
  desc = "Search on current file"
})
vim.keymap.set('n', 'sW', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
  desc = "Search on current file"
})
vim.keymap.set('v', 'sw',
  '<esc><cmd>lua require("spectre").open({ search_text=require("my_funcs").get_text("v"), path=require("my_funcs").GetBufRelativePath()})<CR>',
  {
    desc = "Search select word"
  })
vim.keymap.set('v', 'sW',
  '<esc><cmd>lua require("spectre").open({ search_text=require("my_funcs").get_text("v") })<CR>',
  {
    desc = "Search select word"
  })

-- SnipRun
lvim.keys.normal_mode["<leader>r"] = ":%SnipRun<CR>"
lvim.keys.visual_mode["<leader>r"] = ":'<,'>SnipRun<CR>"

-- Use which-key to add extra bindings with the leader-key prefix
-- orverwirte old 's'
lvim.builtin.which_key.mappings.f = nil
lvim.builtin.which_key.mappings["fy"] = { "<cmd>Telescope neoclip<cr>", "Find clipboard" }
lvim.builtin.which_key.mappings["ff"] =
{ ":lua require('lvim.core.telescope.custom-finders').find_project_files()<cr>", "Find file(project)" }
lvim.builtin.which_key.mappings["fF"] = { ":lua require('telescope.builtin').find_files()<cr>", "Find file" }
lvim.builtin.which_key.mappings["fs"] = { ":lua require('telescope.builtin').live_grep()<cr>", "Find string" }
lvim.builtin.which_key.mappings["fp"] = { "<cmd>Telescope projects<CR>", "Recent projects" }
lvim.builtin.which_key.mappings["fr"] = { ":Telescope oldfiles<cr>", "Recent files" }
lvim.builtin.which_key.mappings["fk"] = { "<cmd>Telescope keymaps<cr>", "Show all keymaps" }
lvim.builtin.which_key.mappings["ft"] = { "<cmd>:TodoTelescope<cr>", "Show all TODOs" }
lvim.builtin.which_key.mappings["fh"] = { ":lua require('telescope.builtin').help_tags()<cr>", "Find helps" }
lvim.builtin.which_key.mappings["fb"] = { ":lua require('telescope').extensions.bookmarks.list()<cr>", "Find bookmarks" }
lvim.builtin.which_key.mappings["fc"] = { ":lua require('telescope.builtin').command_history()<cr>", "History cmd" }

-- use telescope to find string
lvim.builtin.which_key.vmappings["fw"] = { "<Esc>:lua require('my_funcs').live_grep_raw({default_text=''}, 'v')<cr>",
  "Find selection" }
lvim.builtin.which_key.mappings["fw"] = {
  ":lua require('my_funcs').live_grep_raw({default_text = vim.fn.expand('<cword>')})<cr>", "Find word" }
lvim.builtin.which_key.mappings["fd"] = {
  ":lua require('my_funcs').live_grep_raw({default_text =  '-g' .. require('my_funcs').ret_null_if_input_point(vim.fn.fnamemodify(vim.fn.expand('%'), ':.:h')) .. '/*' .. ' ' .. vim.fn.expand('<cword>')})<cr>",
  "Find in the file directory"
}
lvim.builtin.which_key.vmappings["fd"] = {
  ":lua require('my_funcs').live_grep_raw({default_text =  '-g' .. require('my_funcs').ret_null_if_input_point(vim.fn.fnamemodify(vim.fn.expand('%'), ':.:h')) .. '/*' .. ' '},'v')<cr>",
  "Find in the file directory"
}
-- lvim.builtin.which_key.mappings["fe"] = { ":lua require('my_funcs').live_grep_raw({default_text =''})<cr>", "Find null" }


lvim.keys.normal_mode["<leader>m"] = ":lua require('telescope.builtin').lsp_document_symbols()<cr>"
lvim.keys.normal_mode["<leader>M"] = ":lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>"

-- jump config
vim.keymap.set("", "f", function()
  require("hop").hint_char1({
    direction = require("hop.hint").HintDirection.AFTER_CURSOR,
    current_line_only = true,
  })
end, { remap = true })
vim.keymap.set("", "F", function()
  require("hop").hint_char1({
    direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
    current_line_only = true,
  })
end, { remap = true })
vim.keymap.set("", "t", function()
  require("hop").hint_char1({
    direction = require("hop.hint").AFTER_CURSOR,
    current_line_only = true,
    hint_offset = -1,
  })
end, { remap = true })
vim.keymap.set("", "T", function()
  require("hop").hint_char1({
    direction = require("hop.hint").BEFORE_CURSOR,
    current_line_only = true,
    hint_offset = 1,
  })
end, { remap = true })
lvim.builtin.which_key.mappings.s = nil
-- lvim.keys.normal_mode["<leader>s"] = "<cmd>HopChar2<cr>"
-- lvim.keys.normal_mode["<leader>S"] = "<cmd>HopChar2MW<cr>"
lvim.keys.normal_mode["<leader>s"] = "<cmd>lua require('flash').jump()<cr>"


-- Ref: https://github.com/nanotee/nvim-lua-guide/blob/a118d6f585683a94364167d46274595b1959f089/README.md#defining-user-commands
vim.api.nvim_create_user_command('Conda',
  function(opts)
    -- print(string.upper(opts.args))
    local opt = opts.args
    if opt == "switch" then
      require('swenv.api').pick_venv()
    elseif opt == "show" then
      -- Cannot show? https://github.com/AckslD/swenv.nvim/issues/3
      -- require('swenv.api').get_current_venv()
      vim.api.nvim_command("!which python")
    end
  end,
  {
    nargs = 1,
    complete = function(ArgLead, CmdLine, CursorPos)
      -- return completion candidates as a list-like table
      return { 'switch', 'show' }
    end,
  })


-- auto pairs
lvim.builtin.autopairs.disable_filetype = { "TelescopePrompt", "spectre_panel", "repl" }


-- dap
lvim.keys.normal_mode["<F12>"] = ":Telescope dap configurations<cr>"
lvim.builtin.which_key.mappings["dt"] =
{ "<cmd>lua require'persistent-breakpoints.api'.toggle_breakpoint()<cr>", "Toggle Breakpoint" }
lvim.builtin.which_key.mappings["dT"] = {
  "<cmd>lua require'persistent-breakpoints.api'.set_conditional_breakpoint()<cr>",
  "Toggle condition point",
}
lvim.builtin.which_key.mappings["dR"] =
{ "<cmd>lua require'persistent-breakpoints.api'.clear_all_breakpoints()<cr>", "clear all breakpoints" }


-- unmap a default keymapping
-- vim.keymap.del("n", "q")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
  -- for input mode
  i = {
    ["<C-j>"] = actions.cycle_history_next,
    ["<C-k>"] = actions.cycle_history_prev,
    ["<C-n>"] = actions.move_selection_next,
    ["<C-p>"] = actions.move_selection_previous,
  },
  -- for normal mode
  n = {
    ["<C-j>"] = actions.cycle_history_next,
    ["<C-k>"] = actions.cycle_history_prev,
    ["<C-n>"] = actions.move_selection_next,
    ["<C-p>"] = actions.move_selection_previous,
  },
}


lvim.builtin.which_key.mappings["t"] = {
  name = "+Trouble",
  r = { "<cmd>TroubleToggle lsp_references<cr>", "References" },
  f = { "<cmd>TroubleToggle lsp_definitions<cr>", "Definitions" },
  d = { "<cmd>TroubleToggle document_diagnostics<cr>", "Diagnostics" },
  q = { "<cmd>TroubleToggle quickfix<cr>", "QuickFix" },
  -- l = { "<cmd>Trouble loclist<cr>", "LocationList" },
  l = { "<cmd>TroubleToggle loclist<cr>", "LocationList" },
  w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "Workspace Diagnostics" },
  t = { "<cmd>TodoTrouble<cr>", "Todo" },
}

-- lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"


-- ToggleTerminal
lvim.builtin.terminal.active = true
lvim.builtin.terminal.start_in_insert = true
lvim.builtin.terminal.persist_mode = true
lvim.builtin.terminal.execs = {
  { vim.o.shell, "<M-`>",         "Float Terminal",      "float",      nil },
  { vim.o.shell, "<M-Esc>",       "Float Terminal",      "float",      nil },
  { vim.o.shell, "<M-->",         "Horizontal Terminal", "horizontal", 0.3 },
  { vim.o.shell, "<M-\\>",        "Vertical Terminal",   "vertical",   0.4 },
  { vim.o.shell, "<M-BackSpace>", "Vertical Terminal",   "vertical",   0.4 },
}
-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
-- vim.keymap.set("n", "<C-t>", "<cmd>ToggleTerm<cr>")
-- vim.keymap.set("t", "<C-t>", "<cmd>ToggleTerm<cr>")
-- lvim.keys.normal_mode["<C-t>"] = "<cmd>ToggleTerminal<cr>"
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
  -- vim.keymap.set('t', 'jj', [[<C-\><C-n>]], opts) // inconvenient in ranger
  vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
  vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
end

-- nvim tree
lvim.builtin.project.manual_mode = false -- set manual_mode will not auto cwd root directory with git
lvim.builtin.nvimtree.setup.hijack_directories.enable = true
lvim.builtin.nvimtree.setup.hijack_directories.auto_open = true
-- enable nvimtree show icons
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true
lvim.builtin.nvimtree.setup.renderer.icons.glyphs.git = { staged = "✓", untracked = "★" }
lvim.builtin.nvimtree.setup.diagnostics = {
  enable = true,
  show_on_dirs = true,
  icons = {
    hint = "",
    info = "",
    warning = "",
    error = "",
  },
}
lvim.builtin.nvimtree.setup.actions.open_file.quit_on_open = true
lvim.builtin.nvimtree.setup.view = {
  -- 浮动效果不理想，不开了 gxt_kt
  -- float={
  --   enable=false,
  --   quit_on_focus_loss=true,
  --   open_win_config={
  --             relative = "editor",
  --             border = "rounded",
  --             width = 30,
  --             height = 30,
  --             row = 1,
  --             col = 1,
  --   },
  -- },
  width = 30,
  side = "left",
}

-- cmp
lvim.builtin.cmp.cmdline.enable = true
table.insert(lvim.builtin.cmp.sources, {
  name = "nvim_lsp_signature_help",
})

-- gitsigns
lvim.builtin.gitsigns.opts.current_line_blame = false
lvim.builtin.gitsigns.opts.current_line_blame_opts.virt_text_pos = "right_align"
lvim.builtin.gitsigns.opts.current_line_blame_opts.delay = 200


-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  -- "all",
  "bash",
  "c",
  "cpp",
  "json",
  "lua",
  "python",
  "yaml",
  "rust",
  "markdown",
  "markdown_inline",
}
-- lvim.builtin.treesitter.auto_install = false
-- lvim.builtin.treesitter.ensure_installed="all"

lvim.builtin.treesitter.highlight.enable = true

-- About treesitter config my rainbow color see https://github.com/p00f/nvim-ts-rainbow/issues/104
lvim.builtin.treesitter.rainbow.enable = false
lvim.builtin.treesitter.rainbow.extended_mode = true
lvim.builtin.treesitter.rainbow.max_file_lines = 500 -- default is 1000
lvim.builtin.treesitter.rainbow.colors = {
  "#d65d0e",
  "#689d6a",
  "#b16286",
  "#89ddff",
  "#d79921",
  "#a89984",
  "#cc241d",
}
-- solve bug that treesitter rainbow bracket will missup when format the code
-- Ref: https://github.com/p00f/nvim-ts-rainbow/issues/112#issuecomment-1310835936
-- vim.cmd(
--   [[autocmd BufNewFile,BufReadPost * TSDisable rainbow | TSEnable rainbow | TSDisable rainbow | TSEnable rainbow | TSDisable rainbow | TSEnable rainbow]]
-- )


-- generic LSP settings
-- -- make sure server will always be installed even if the server is in skipped_servers list
-- ---@usage disable automatic installation of servers
lvim.lsp.installer.setup.automatic_installation = false
-- lvim.lsp.installer.setup.ensure_installed = {
--   "clangd",
--   "pyright",
-- }

-- -- change UI setting of `LspInstallInfo`
-- -- see <https://github.com/williamboman/nvim-lsp-installer#default-configuration>
-- lvim.lsp.installer.setup.ui.check_outdated_servers_on_open = false
-- lvim.lsp.installer.setup.ui.border = "rounded"
-- lvim.lsp.installer.setup.ui.keymaps = {
--     uninstall_server = "d",
--     toggle_server_expand = "o",
-- }


-- disable diagnostics which is super annoying in my case
-- lvim.lsp.diagnostics.virtual_text = true
-- lvim.diagnostic.config({ virtual_text = true })

lvim.lsp.buffer_mappings.normal_mode["gh"] = { vim.lsp.buf.hover, "Show documentation" }

-- vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
--
---@diagnostic disable-next-line: missing-parameter
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright", "clangd" })
require("lvim.lsp.manager").setup("pyright", {
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
        typeCheckingMode = "off",
        autoImportCompletions = true,
      },
    },
  },
})

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "pylsp"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
-- require "lsp_signature".on_attach()
-- end

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
  { command = "black", filetypes = { "python" } },

  -- { command = "isort", filetypes = { "python" } },
  -- {
  --   -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
  --   command = "prettier",
  --   ---@usage arguments to pass to the formatter
  --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
  --   extra_args = { "--print-with", "100" },
  --   ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
  --   filetypes = { "typescript", "typescriptreact" },
  -- },
})

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   -- { command = "flake8", filetypes = { "python" } },
--   -- {
--   --   -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--   --   command = "shellcheck",
--   --   ---@usage arguments to pass to the formatter
--   --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--   --   extra_args = { "--severity", "warning" },
--   -- },
--   {
--     command = "cpplint",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "c", "cpp" },
--   },
-- }

lvim.lsp.null_ls.setup.on_init = function(new_client, _)
  new_client.offset_encoding = "utf-16"
end



--- dap config
-- load non-standard json file
-- require('dap.ext.vscode').json_decode = require 'json5'.parse
-- require('dap.ext.vscode').load_launchjs()
-- require("dap.dap-lldb")
-- require("dap.dap-cppdbg")

-- gxt_kt debug config :
lvim.builtin.dap.active = true
require("dap.dap-lldb")
require('dap.python')
require('dap.c_cpp_rust')

-- Associate .launch files with the xml language
vim.cmd([[autocmd BufNewFile,BufRead *.launch set filetype=xml]])


-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
--
--
--
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  command = "set tabstop=4  shiftwidth=4",
})

-- Sovle txt bug use kitty+tmux and show image
-- https://github.com/neovim/neovim/issues/21856
vim.api.nvim_create_autocmd({ "VimLeave" }, {
  callback = function()
    -- do nothing
    vim.fn.jobstart('', { detach = true })
  end,
})
