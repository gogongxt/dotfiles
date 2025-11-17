-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local function setup_toggleterm_provider()
  local Terminal = require("toggleterm.terminal").Terminal
  local toggleterm = require "toggleterm"

  -- Store the claude terminal instance
  local claude_terminal = nil

  local function get_or_create_claude_terminal(cmd_string, env_table, config)
    -- Use config.cwd if provided, otherwise use current working directory
    local cwd = config and config.cwd or vim.fn.getcwd()

    -- Determine terminal size based on config
    local size = nil
    if config and config.split_width_percentage then
      -- For vertical splits, calculate the exact width
      size = math.floor(vim.o.columns * config.split_width_percentage)
      -- Ensure minimum size of 20 columns and maximum of 120 columns
      size = math.max(20, math.min(size, 120))
    end

    -- Determine direction based on split_side config
    -- toggleterm uses 'vertical' for both left and right splits
    local direction = "vertical"

    if not claude_terminal then
      claude_terminal = Terminal:new {
        cmd = cmd_string,
        dir = cwd,
        direction = direction,
        env = env_table,
        display_name = "Claude Code",
        close_on_exit = config and config.auto_close ~= false, -- Default to true unless explicitly false
        auto_scroll = false,
        hidden = false, -- Make it discoverable by normal toggleterm commands
        on_open = function(term)
          -- Set up terminal-specific keymaps if needed
          if term.bufnr then
            vim.api.nvim_buf_set_var(term.bufnr, "toggle_number", term.id)
            -- Map Ctrl+/ to send ESC to terminal
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-_>", "<Esc>", { noremap = true, silent = true })
          end
          -- Start insert mode when opening
          vim.cmd "startinsert"
        end,
        on_close = function(term)
          -- Clean up when terminal is closed
          vim.cmd "stopinsert"
        end,
        float_opts = {
          width = math.floor(vim.o.columns * 0.8),
          height = math.floor(vim.o.lines * 0.8),
          border = "single",
          winblend = 3,
        },
      }
    else
      -- Update command, environment, and directory if needed
      claude_terminal.cmd = cmd_string
      claude_terminal.env = env_table
      claude_terminal.dir = cwd
      -- Update close_on_exit setting if it changed
      if config then claude_terminal.close_on_exit = config.auto_close ~= false end
    end

    -- Handle split positioning and resizing (toggleterm doesn't directly support
    -- left/right positioning in the constructor, but we can move and resize after it opens)
    local original_open = claude_terminal.open
    claude_terminal.open = function(self, size_override, direction_override)
      -- Call the original open function
      original_open(self, size, direction_override)

      -- Move and resize window if it's a vertical split and we have config
      if self:is_open() and self.window and config then
        if config.split_side then
          if config.split_side == "left" then
            -- Move to the leftmost position
            vim.api.nvim_win_call(self.window, function() vim.cmd "wincmd H" end)
          elseif config.split_side == "right" then
            -- Move to the rightmost position
            vim.api.nvim_win_call(self.window, function() vim.cmd "wincmd L" end)
          end
        end

        -- Apply exact width resizing if specified
        if size and config.split_width_percentage then
          vim.api.nvim_win_call(self.window, function() vim.cmd("vertical resize " .. size) end)
        end
      end
    end

    return claude_terminal
  end

  return {
    setup = function(config)
      -- No specific setup needed for toggleterm provider
      -- But we can store any global config here if needed
    end,

    open = function(cmd_string, env_table, config, focus)
      focus = focus ~= false -- Default to true
      local term = get_or_create_claude_terminal(cmd_string, env_table, config)

      if not term:is_open() then term:open() end

      if focus and term.window then
        vim.api.nvim_set_current_win(term.window)
        vim.cmd "startinsert"
      end
    end,

    close = function()
      if claude_terminal and claude_terminal:is_open() then claude_terminal:close() end
    end,

    toggle = function(cmd_string, env_table, effective_config)
      local term = get_or_create_claude_terminal(cmd_string, env_table, effective_config)
      term:toggle()
    end,

    simple_toggle = function(cmd_string, env_table, effective_config)
      local term = get_or_create_claude_terminal(cmd_string, env_table, effective_config)
      term:toggle()
    end,

    focus_toggle = function(cmd_string, env_table, effective_config)
      local term = get_or_create_claude_terminal(cmd_string, env_table, effective_config)

      if not term:is_open() then
        term:open()
        if term.window then
          vim.api.nvim_set_current_win(term.window)
          vim.cmd "startinsert"
        end
      else
        -- Terminal is open, check if it's focused
        local current_win = vim.api.nvim_get_current_win()
        if term.window == current_win then
          -- Terminal is focused, close it
          term:close()
        else
          -- Terminal is open but not focused, focus it
          if term.window then
            vim.api.nvim_set_current_win(term.window)
            vim.cmd "startinsert"
          end
        end
      end
    end,

    get_active_bufnr = function()
      if claude_terminal and claude_terminal.bufnr and claude_terminal:is_open() then return claude_terminal.bufnr end
      return nil
    end,

    is_available = function()
      local ok, _ = pcall(require, "toggleterm")
      return ok
    end,

    ensure_visible = function()
      if claude_terminal and not claude_terminal:is_open() then claude_terminal:open() end
    end,

    _get_terminal_for_test = function() return claude_terminal end,
  }
end

return {
  "coder/claudecode.nvim",
  dependencies = { "akinsho/toggleterm.nvim" },
  opts = {
    -- terminal_cmd = "ccr code",
    terminal_cmd = "claude",
    focus_after_send = true, -- When true, successful sends will focus the Claude terminal if already connected
    track_selection = true,

    -- Terminal Configuration
    terminal = {
      split_side = "right", -- "left" or "right"
      split_width_percentage = 0.40,
      provider = setup_toggleterm_provider(),
      auto_close = true, -- Works with toggleterm provider
      -- snacks_win_opts = {
      --   -- auto_insert = false,
      -- }, -- Not used with toggleterm provider
    },
  },
  config = true,
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>as", "<cmd>ClaudeCodeAdd %<cr>", mode = "n", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
