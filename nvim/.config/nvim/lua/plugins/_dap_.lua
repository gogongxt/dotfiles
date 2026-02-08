-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = { "debugpy", "codelldb" },
    },
  },
  {
    "mfussenegger/nvim-dap-python",
    config = function()
      local debugpy_path = vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python3"
      require("dap-python").setup(debugpy_path)
    end,
  },
  {
    "gogongxt/nvim-dap-virtual-text",
    config = function()
      -- 设置 virtual text 高亮，使其与注释颜色区分开（蓝色系）
      vim.api.nvim_set_hl(0, "NvimDapVirtualText", { fg = "#61afef", italic = true })
      vim.api.nvim_set_hl(0, "NvimDapVirtualTextChanged", { fg = "#4fc3ff", bold = true, italic = true })

      require("nvim-dap-virtual-text").setup {
        enabled = true, -- enable this plugin (the default)
        enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
        highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
        highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
        show_stop_reason = true, -- show stop reason when stopped for exceptions
        commented = false, -- prefix virtual text with comment string
        only_first_definition = true, -- only show virtual text at first definition (if there are multiple)
        all_references = true, -- show virtual text on all all references of the variable (not only definitions)
        clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
        --- A callback that determines how a variable is displayed or whether it should be omitted
        --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
        --- @param buf number
        --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
        --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
        --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
        --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
        display_callback = function(variable, buf, stackframe, node, options)
          -- by default, strip out new line characters
          if options.virt_text_pos == "inline" then
            return " = " .. variable.value:gsub("%s+", " ")
          else
            return variable.name .. " = " .. variable.value:gsub("%s+", " ")
          end
        end,
        -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
        -- virt_text_pos = vim.fn.has "nvim-0.10" == 1 and "inline" or "eol",
        virt_text_pos = "eol",
        -- priority of virtual text, see `:h nvim_buf_set_extmark()`
        priority = 200,

        -- experimental features:
        all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
        virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
        virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
        -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
      }
    end,
  },
  {
    "mfussenegger/nvim-dap",
  },
  {
    "igorlfs/nvim-dap-view",
    opts = {
      winbar = {
        -- You can add a "console" section to merge the terminal with the other views
        sections = { "console", "scopes", "watches", "exceptions", "breakpoints", "threads", "repl" },
        -- Must be one of the sections declared above
        default_section = "console",
        -- Append hints with keymaps within the labels
        show_keymap_hints = true,
        -- Configure each section individually
        base_sections = {
          -- Labels can be set dynamically with functions
          -- Each function receives the window's width and the current section as arguments
          breakpoints = { label = "Breakpoints", keymap = "B" },
          scopes = { label = "Scopes", keymap = "S" },
          exceptions = { label = "Exceptions", keymap = "E" },
          watches = { label = "Watches", keymap = "W" },
          threads = { label = "Threads", keymap = "T" },
          repl = { label = "REPL", keymap = "R" },
          sessions = { label = "Sessions", keymap = "K" },
          console = { label = "Console", keymap = "C" },
        },
        -- Add your own sections
        custom_sections = {},
        controls = {
          enabled = true,
          position = "right",
          buttons = {
            "play",
            "step_into",
            "step_over",
            "run_to_cursor",
            "step_out",
            "step_back",
            "run_last",
            "terminate",
            "disconnect",
          },
          custom_buttons = {
            run_to_cursor = {
              render = function()
                local dap = require "dap"
                local session = dap.session()
                local stopped = session and session.stopped_thread_id
                local hl = stopped and "ControlStepInto" or "ControlNC"
                return "%#NvimDapView" .. hl .. "#" .. "" .. "%*"
              end,
              action = function() require("dap").run_to_cursor() end,
            },
          },
        },
      },
      icons = {
        collapsed = "󰅂 ",
        disabled = "",
        disconnect = "",
        enabled = "",
        expanded = "󰅀 ",
        filter = "󰈲",
        negate = " ",
        pause = "",
        play = "",
        run_last = "",
        step_back = "",
        step_into = "",
        step_out = "",
        step_over = "",
        terminate = "",
      },
    },
    -- 添加 terminal 窗口导航 keymap
    config = function(_, opts)
      require("dap-view").setup(opts)
      -- 为 REPL/Console terminal buffer 添加窗口导航
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "dap-repl" },
        callback = function(event)
          local buf = event.buf
          local has_smart_splits = pcall(require, "smart-splits")
          -- 支持 niv 三种模式：优先使用 smart-splits，否则使用 wincmd
          if has_smart_splits then
            vim.keymap.set(
              { "n", "i", "v" },
              "<C-h>",
              [[<cmd>lua require('smart-splits').move_cursor_left()<cr>]],
              { buffer = buf }
            )
            vim.keymap.set(
              { "n", "i", "v" },
              "<C-j>",
              [[<cmd>lua require('smart-splits').move_cursor_down()<cr>]],
              { buffer = buf }
            )
            vim.keymap.set(
              { "n", "i", "v" },
              "<C-k>",
              [[<cmd>lua require('smart-splits').move_cursor_up()<cr>]],
              { buffer = buf }
            )
            vim.keymap.set(
              { "n", "i", "v" },
              "<C-l>",
              [[<cmd>lua require('smart-splits').move_cursor_right()<cr>]],
              { buffer = buf }
            )
          else
            vim.keymap.set({ "n", "i", "v" }, "<C-h>", [[<Cmd>wincmd h<CR>]], { buffer = buf })
            vim.keymap.set({ "n", "i", "v" }, "<C-j>", [[<Cmd>wincmd j<CR>]], { buffer = buf })
            vim.keymap.set({ "n", "i", "v" }, "<C-k>", [[<Cmd>wincmd k<CR>]], { buffer = buf })
            vim.keymap.set({ "n", "i", "v" }, "<C-l>", [[<Cmd>wincmd l<CR>]], { buffer = buf })
          end
          -- vim.keymap.set("i", "<C-w>", function() return "<C-o>vbd" end, { buffer = buf, expr = true })
          vim.keymap.set("i", "<C-w>", "<C-S-w>", { buffer = true }) -- https://github.com/mfussenegger/nvim-dap/issues/786
        end,
      })
    end,
  },
  {
    "gogongxt/persistent-breakpoints.nvim",
    event = "BufReadPost",
    opts = function(_, opts)
      return require("astrocore").extend_tbl(opts, {
        load_breakpoints_event = { "BufReadPost" },
        save_dir = vim.fn.getcwd() .. "/.nvim/dap_breakpoints",
        filename = "breakpoints", -- filename set to breakpoints.json
      })
    end,
    keys = {
      {
        "<Leader>db",
        function() require("persistent-breakpoints.api").toggle_breakpoint() end,
        { silent = true },
        desc = "Toggle Breakpoint",
      },
      {
        "<Leader>dB",
        function() require("persistent-breakpoints.api").clear_all_breakpoints() end,
        { silent = true },
        desc = "Clear Breakpoints",
      },
      {
        "<Leader>dC",
        function() require("persistent-breakpoints.api").set_conditional_breakpoint() end,
        { silent = true },
        desc = "Conditional Breakpoint",
      },
    },
  },
}
