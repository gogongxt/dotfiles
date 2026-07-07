-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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
    if not choice then return end
    -- terminal_cmd sources ~/.zshrc → ~/.user.sh, which re-evaluates the vendor
    -- block from CLAUDE_CODE_VENDOR, so the new session picks up the right ANTHROPIC_* vars.
    vim.env.CLAUDE_CODE_VENDOR = choice
    vim.notify("Claude vendor: " .. choice .. " — starting new session", vim.log.levels.INFO)
    vim.cmd "ClaudeCodeNew"
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
  local best, best_time = nil, 0
  for _, info in ipairs(vim.fn.getbufinfo { buflisted = 1 }) do
    if info.loaded == 1 and info.name:find "claude%-prompt.*%.md$" then
      local mtime = vim.fn.getftime(info.name)
      if mtime > best_time then
        best, best_time = info.bufnr, mtime
      end
    end
  end
  return best
end

function _G.claude_prompt.append(text, bufnr)
  bufnr = bufnr or 0
  local ok, err = pcall(function()
    -- Inline append at end of last line to match Claude's native " ... " behavior.
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local last_line = vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1] or ""
    local sep = (last_line == "" or last_line:sub(-1) == " ") and "" or " "
    local new_line = last_line .. sep .. text .. " "
    vim.api.nvim_buf_set_lines(bufnr, line_count - 1, line_count, false, { new_line })
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == bufnr then
        vim.api.nvim_win_set_cursor(win, { line_count, #new_line })
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

function _G.claude_filetree_add_wrapper()
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
end

function _G.claude_send_wrapper()
  if _G.claude_prompt.find_buf() then
    local l1 = vim.fn.line "."
    local l2 = vim.fn.line "v"
    if l1 > l2 then
      l1, l2 = l2, l1
    end
    local file = vim.fn.expand "%:p"
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "i", true)
    vim.schedule(function()
      if file ~= "" then _G.claude_prompt.append_ref(file, l1, l2) end
    end)
    return
  end
  vim.cmd "ClaudeCodeSend"
end

-- Shared key → { action, desc } table for the <C-s> prefix bindings that should
-- work both in normal/visual mode (lazy `keys`) and inside the Claude terminal
-- (terminal mode `t`). `action` is either a command string (wrapped in
-- <cmd>...<cr>) or a function (used directly). Each side generates its own
-- mapping from this single source so a binding change only needs editing once.
local claude_keys = {
  ["<C-s><C-s>"] = { "ClaudeCode", "Toggle active Claude session" },
  ["<C-s>n"] = { "ClaudeCodeNew", "New Claude session" },
  ["<C-s>l"] = { "ClaudeCodeSessions", "List/pick Claude session" },
  ["<C-s>q"] = { "ClaudeCodeCloseSession", "Close active Claude session" },
  ["<C-s>r"] = { "ClaudeCodeRenameSession", "Rename active Claude session" },
  ["<C-s>m"] = { "ClaudeCodeSelectModel", "Select Claude model" },
  ["<C-s>f"] = { "ClaudeCodeFocus", "Focus Claude" },
  ["<C-s>C"] = { select_claude_vendor, "Select Claude Vendor" },
  ["<C-s>R"] = { resume_claude_with_session, "Resume Claude by session-id" },
}
-- <C-s>1..9 → toggle session slot N (1-9 only; plugin supports any N).
for i = 1, 9 do
  claude_keys[string.format("<C-s>%d", i)] = {
    string.format("ClaudeCodeSessions %d", i),
    string.format("Toggle Claude session %d", i),
  }
end

-- Build a keymap rhs from a claude_keys entry: a function is used directly, a
-- command string is wrapped in <cmd>...<cr>.
local function claude_rhs(entry)
  local action = entry[1]
  if type(action) == "function" then return action end
  return "<cmd>" .. action .. "<cr>"
end

-- Variant selector: pick between the upstream plugin and the multi-session
-- fork. Only the multi-session variant ships the `tabs` config (it has no
-- effect on upstream's single-terminal provider).
--   "upstream"      → coder/claudecode.nvim (default branch) + toggleterm provider
--   "multi-session" → gogongxt/claudecode.nvim @ feat/multi-session-terminal + toggleterm built-in
local claude_variant = "multi-session"
local claude_repo, claude_branch, claude_terminal_provider, claude_tabs
if claude_variant == "multi-session" then
  claude_repo = "gogongxt/claudecode.nvim"
  claude_branch = "feat/multi-session-terminal"
  claude_terminal_provider = "toggleterm"
  -- Multi-session tab bar. Keymaps default to false so terminal-native keys
  -- (<Tab>, <S-Tab>, <C-w>) pass through to Claude's TUI untouched. We opt
  -- into <C-Tab>/<C-S-Tab> only — they don't conflict with the TUI.
  claude_tabs = {
    enabled = true,
    show_close_button = true,
    show_new_button = true,
    keymaps = {
      next_tab = "<Tab>",
      -- prev_tab = "<S-Tab>",
      prev_tab = false,
      new_tab = false,
      close_tab = false,
    },
  }
else
  claude_repo = "coder/claudecode.nvim"
  claude_branch = nil -- default branch
  claude_terminal_provider = require "utils.claude-toggleterm-provider"()
  claude_tabs = {}
end

return {
  claude_repo,
  branch = claude_branch,
  -- dir = "~/Projects/claudecode.nvim",
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
      provider = claude_terminal_provider,
      -- provider = "toggleterm", -- built-in provider; uses toggleterm.nvim, falls back to native if unavailable
      auto_close = true, -- Works with toggleterm provider
      -- snacks_win_opts = {
      --   -- auto_insert = false,
      -- }, -- Not used with toggleterm provider
      tabs = claude_tabs,
    },
  },
  config = function(_, opts)
    require("claudecode").setup(opts)

    -- Terminal-mode <C-s> bindings: inside the Claude terminal, <C-s> would be
    -- forwarded to Claude's TUI. Intercept it in terminal mode (t) so the
    -- <C-s>X shortcuts work without leaving the terminal. Bare <C-s> is mapped
    -- to <Nop> so Neovim waits for the next key to complete the combo (terminal
    -- mode has no timeoutlen, so without this the prefix reaches Claude
    -- immediately). The provider's restore_mode re-enters insert after the
    -- command, so a plain <cmd>...<cr> rhs suffices.
    vim.keymap.set("t", "<C-s>", "<Nop>", { silent = true, desc = "Claude prefix (swallow)" })
    for lhs, entry in pairs(claude_keys) do
      vim.keymap.set("t", lhs, claude_rhs(entry), {
        silent = true,
        desc = entry[2],
      })
    end

    -- Normal-mode mouse wheel passthrough: in terminal-normal mode ("n"),
    -- Neovim handles <ScrollWheelUp/Down> itself but a terminal buffer has no
    -- native scroll target, so the wheel does nothing. Claude's TUI enables
    -- SGR mouse tracking (mode 1006), so in terminal mode ("t") the wheel
    -- reaches the PTY directly. Intercept the wheel in normal mode on Claude
    -- terminal buffers and forward an SGR wheel event to the PTY channel,
    -- mimicking what Neovim would have sent in terminal mode.
    local install_wheel_passthrough = function(bufnr)
      if vim.b[bufnr].claudecode_wheel_passthrough then return end
      vim.b[bufnr].claudecode_wheel_passthrough = true
      local send_sgr = function(button, col, row)
        -- SGR mouse format: ESC [ < button ; col ; row M (press) / m (release)
        local seq = string.format("\27[<%d;%d;%dM", button, col, row)
        local chan = vim.bo[bufnr].channel
        if chan and chan > 0 then vim.api.nvim_chan_send(chan, seq) end
      end
      local dispatch_wheel = function(button)
        -- getmousepos() returns {winid, screenrow, screencol, winrow, wincol, line, column}.
        -- SGR mouse coordinates are terminal-screen-relative (1-indexed).
        local m = vim.fn.getmousepos()
        if not m then return end
        local winid = m.winid
        if not winid or not vim.api.nvim_win_is_valid(winid) then return end
        if vim.api.nvim_win_get_buf(winid) ~= bufnr then return end
        local col = m.screencol or 1
        local row = m.screenrow or 1
        if col < 1 then col = 1 end
        if row < 1 then row = 1 end
        -- SGR wheel: a single press event with the wheel button code.
        -- No release event is needed (wheel buttons are momentary).
        send_sgr(button, col, row)
      end
      vim.keymap.set(
        "n",
        "<ScrollWheelUp>",
        function() dispatch_wheel(64) end,
        { buffer = bufnr, silent = true, desc = "Claude wheel up → PTY" }
      )
      vim.keymap.set(
        "n",
        "<ScrollWheelDown>",
        function() dispatch_wheel(65) end,
        { buffer = bufnr, silent = true, desc = "Claude wheel down → PTY" }
      )
      -- Horizontal wheel (rare, but harmless to forward too).
      vim.keymap.set(
        "n",
        "<ScrollWheelLeft>",
        function() dispatch_wheel(66) end,
        { buffer = bufnr, silent = true, desc = "Claude wheel left → PTY" }
      )
      vim.keymap.set(
        "n",
        "<ScrollWheelRight>",
        function() dispatch_wheel(67) end,
        { buffer = bufnr, silent = true, desc = "Claude wheel right → PTY" }
      )
    end
    local is_claude_term_buf = function(bufnr)
      local ok, term_mod = pcall(require, "claudecode.terminal")
      if not ok then return false end
      -- get_session_for_buffer is buffer-local and authoritative; fall back to
      -- get_active_terminal_bufnr for older plugin revisions that lack it.
      if term_mod.get_session_for_buffer then return term_mod.get_session_for_buffer(bufnr) ~= nil end
      if term_mod.get_active_terminal_bufnr then return term_mod.get_active_terminal_bufnr() == bufnr end
      return false
    end
    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("ClaudeCodeWheelPassthrough", { clear = true }),
      callback = function(args)
        local bufnr = args.buf
        if is_claude_term_buf(bufnr) then
          install_wheel_passthrough(bufnr)
          return
        end
        -- Active-bufnr registration may lag TermOpen by a tick; recheck deferred.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) and is_claude_term_buf(bufnr) then install_wheel_passthrough(bufnr) end
        end)
      end,
    })

    -- C-d / C-u half-page scroll is now handled Claude-side via
    -- ~/.claude/keybindings.json (Scroll context: ctrl+d → scroll:halfPageDown,
    -- ctrl+u → scroll:halfPageUp). See GitHub issue #64992 — the "reserved"
    -- restriction on Ctrl+D only protects the Global app:exit default; a more
    -- specific context (Scroll) can shadow it. Caveat per #64992: ctrl+u
    -- shares byte 0x15 with Cmd+Backspace, so Cmd+Backspace in the Claude
    -- prompt stops deleting to line start. To restore the neovim-side
    -- workaround (which avoids the byte collision), uncomment the block below
    -- and remove the Scroll-context binding from keybindings.json.
    --[[
    local PGUP = "\27[5~"
    local PGDN = "\27[6~"
    local install_scroll_keys = function(bufnr)
      if vim.b[bufnr].claudecode_scroll_keys then return end
      vim.b[bufnr].claudecode_scroll_keys = true
      local send_bytes = function(seq)
        return function()
          local chan = vim.bo[bufnr].channel
          if chan and chan > 0 then vim.api.nvim_chan_send(chan, seq) end
        end
      end
      vim.keymap.set(
        "t",
        "<C-d>",
        send_bytes(PGDN),
        { buffer = bufnr, silent = true, desc = "Claude scroll half-page down" }
      )
      vim.keymap.set(
        "t",
        "<C-u>",
        send_bytes(PGUP),
        { buffer = bufnr, silent = true, desc = "Claude scroll half-page up" }
      )
    end
    local is_claude_buf = function(bufnr)
      local ok, term_mod = pcall(require, "claudecode.terminal")
      if not ok then return false end
      local active = term_mod.get_active_terminal_bufnr and term_mod.get_active_terminal_bufnr()
      return active == bufnr
    end
    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("ClaudeCodeScrollKeys", { clear = true }),
      callback = function(args)
        local bufnr = args.buf
        if is_claude_buf(bufnr) then
          install_scroll_keys(bufnr)
          return
        end
        -- Active-bufnr registration may lag TermOpen by a tick; recheck deferred.
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(bufnr) and is_claude_buf(bufnr) then install_scroll_keys(bufnr) end
        end)
      end,
    })
    ]]
  end,
  keys = function()
    local k = {
      { "<c-s>", nil, desc = "AI/Claude Code" },
      -- { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      {
        "<c-s>s",
        _G.claude_add_wrapper,
        mode = "n",
        desc = "Add current buffer",
      },
      {
        "<c-s>s",
        _G.claude_send_wrapper,
        mode = "v",
        desc = "Send to Claude",
      },
      {
        "<c-s>s",
        _G.claude_filetree_add_wrapper,
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles" },
      },
    }
    -- Shared <C-s>X bindings (same source as the terminal-mode mappings above).
    for lhs, entry in pairs(claude_keys) do
      table.insert(k, { lhs, claude_rhs(entry), desc = entry[2] })
    end
    -- Diff management
    -- table.insert(k, { "<c-s>a", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" })
    -- table.insert(k, { "<c-s>d", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" })
    return k
  end,
}
