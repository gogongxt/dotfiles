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
            -- Map Ctrl+/ and Ctrl+_ to send ESC to terminal (they produce same byte in terminal)
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-/>", "<Esc>", { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-_>", "<Esc>", { noremap = true, silent = true })
          end
          -- Set buffer options for better terminal rendering
          if term.window and vim.api.nvim_win_is_valid(term.window) then
            -- Disable wrap to prevent line break issues
            vim.wo[term.window].wrap = false
            -- Set scrolloff to 0 for accurate cursor positioning
            vim.wo[term.window].scrolloff = 0
            vim.wo[term.window].sidescrolloff = 0
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

local claude_cmd = "source ~/.zshrc && claude"

-- Claude API vendors parsed from ~/.user.sh delimited block
local function get_claude_vendors()
  local f = io.open(vim.fn.expand "~/.user.sh", "r")
  if not f then return { "none" } end
  local content = f:read "*a"
  f:close()

  local block = content:match "# >>> gogongxt claudecode config >>>(.-)# <<< gogongxt claudecode config <<<"
  if not block then return { "none" } end

  local vendors = {}
  local seen = {}
  for v in block:gmatch "%s+(%w+)%s*%)" do
    if not seen[v] and v ~= "case" and v ~= "esac" then
      seen[v] = true
      vendors[#vendors + 1] = v
    end
  end
  return #vendors > 0 and vendors or { "none" }
end

local function select_claude_vendor()
  local vendors = get_claude_vendors()
  local current = vim.env.CLAUDE_CODE_VENDOR
  vim.ui.select(vendors, {
    prompt = "Select Claude Vendor:",
    format_item = function(item) return item == current and (item .. " (current)") or item end,
  }, function(choice)
    if choice then
      vim.env.CLAUDE_CODE_VENDOR = choice
      vim.notify("Claude vendor: " .. choice, vim.log.levels.INFO)
    end
  end)
end

local function resume_claude_with_session()
  vim.ui.input({ prompt = "Claude session-id: " }, function(input)
    if not input then return end
    local session = vim.trim(input)
    if session == "" then
      vim.notify("Claude resume cancelled: empty session-id", vim.log.levels.WARN)
      return
    end
    vim.cmd(("ClaudeCode --resume %s"):format(vim.fn.shellescape(session)))
  end)
end

-- Global module for appending file references to Claude prompt temp files
_G.claude_prompt = {}

function _G.claude_prompt.find_buf()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name:find "claude%-prompt.*%.md$" then return bufnr end
    end
  end
  return nil
end

function _G.claude_prompt.append(text, bufnr)
  bufnr = bufnr or 0
  local ok, err = pcall(function()
    local lines = vim.split(text, "\n", { plain = true })
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, line_count, line_count, false, lines)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        vim.api.nvim_win_set_cursor(win, { line_count + #lines, 0 })
        break
      end
    end
    vim.cmd "redraw"
  end)
  if not ok then vim.notify("[claude] append ERROR: " .. tostring(err), vim.log.levels.ERROR) end
end

--- Append file reference to prompt buffer. Returns true if handled, false otherwise.
--- file_path: absolute path, line_start/line_end: optional 1-indexed line range
function _G.claude_prompt.append_ref(file_path, line_start, line_end)
  local prompt_buf = _G.claude_prompt.find_buf()
  if not prompt_buf then return false end
  local rel = vim.fn.fnamemodify(file_path, ":.")
  local ref = "@" .. rel
  if line_start and line_end then
    ref = line_start == line_end and (ref .. "#L" .. line_start) or (ref .. "#L" .. line_start .. "-" .. line_end)
  end
  _G.claude_prompt.append(ref, prompt_buf)
  vim.notify("[claude] appended " .. ref, vim.log.levels.INFO)
  return true
end

function _G.claude_add_wrapper()
  local file = vim.fn.expand "%:p"
  if file ~= "" and _G.claude_prompt.append_ref(file) then return end
  vim.cmd "ClaudeCodeAdd %"
end

local ESC_KEY = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)

function _G.claude_send_wrapper()
  if _G.claude_prompt.find_buf() then
    local l1 = vim.fn.line "."
    local l2 = vim.fn.line "v"
    if l1 > l2 then
      l1, l2 = l2, l1
    end
    local file = vim.fn.expand "%:p"
    vim.api.nvim_feedkeys(ESC_KEY, "i", true)
    vim.schedule(function()
      if file ~= "" then _G.claude_prompt.append_ref(file, l1, l2) end
    end)
    return
  end
  vim.cmd "ClaudeCodeSend"
end

return {
  "coder/claudecode.nvim",
  dependencies = { "akinsho/toggleterm.nvim" },
  opts = {
    -- terminal_cmd = "ccr code",
    -- terminal_cmd = "claude",
    terminal_cmd = claude_cmd,
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
    { "<leader>a",  nil,                              desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
    { "<leader>aC", select_claude_vendor,             desc = "Select Claude Vendor" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
    { "<leader>ar", resume_claude_with_session,      desc = "Resume Claude by session-id" },
    -- { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>as", _G.claude_add_wrapper,            mode = "n",                   desc = "Add current buffer" },
    { "<leader>as", _G.claude_send_wrapper,           mode = "v",                   desc = "Send to Claude" },
    {
      "<leader>as",
      function()
        if _G.claude_prompt.find_buf() then
          local ft = vim.bo.filetype
          local path = nil
          if ft == "neo-tree" then
            local ok, manager = pcall(require, "neo-tree.sources.manager")
            if ok then
              local state = manager.get_state "filesystem"
              if state and state.tree then
                local node = state.tree:get_node()
                if node and node.path then path = node.path end
              end
            end
          elseif ft == "NvimTree" then
            local ok, api = pcall(require, "nvim-tree.api")
            if ok then
              local node = api.tree.get_node_under_cursor()
              if node and node.absolute_path then path = node.absolute_path end
            end
          elseif ft == "oil" then
            local ok, oil = pcall(require, "oil")
            if ok then
              local dir = oil.get_current_dir()
              local entry = oil.get_entry_on_line(0, vim.fn.line ".")
              if dir and entry and entry.name and entry.name ~= ".." then path = dir .. entry.name end
            end
          end
          if path and path ~= "" then _G.claude_prompt.append_ref(path) end
          return
        end
        vim.cmd "ClaudeCodeTreeAdd"
      end,
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
  },
}
