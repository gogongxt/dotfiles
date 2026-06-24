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
      provider = require("utils.claude-toggleterm-provider")(),
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
