-- Custom foldtext with treesitter syntax highlighting.
--
-- Two algorithms:
--   * "bufline" (default) — ported from OXY2DEV/foldtext.nvim. Joins the
--     start and end line with the line-count marker in the middle; both
--     lines carry per-character treesitter highlights.
--   * "regex" — original implementation. Only shows the end line when it
--     matches a list of closing-symbol patterns (end, }, ], ), etc.).
--
-- Switch algorithm by editing `M.algorithm` below, or call
-- `require("utils.foldtext").setup { algorithm = "regex" }`.

local M = {}

---@type "bufline" | "regex"
M.algorithm = "bufline"

-- Icon + line-count marker highlight group.
local COUNT_HL = "CustomFoldText"
local COUNT_ICON = " "

-- Closing-symbol patterns for the "regex" algorithm.
local CLOSE_PATTERNS = {
  "end[f]?", -- end, endif (vim, lua, ruby, etc.)
  "fi", -- if 结束
  "done", -- do/for/while 结束
  "esac", -- case 结束 (shell)
  "[f]unc[tion]?", -- function/endfunction (vim, etc.)
  "endclass", -- class 结束
  "endstruct", -- struct 结束
  "[%])}]+[,;]?", -- }, ], ) 后跟可选的逗号或分号
  "['\"`]", -- 引号
  "</[%w%-]*>", -- HTML/XML 标签结束
}

--- Capture names that do not carry highlight info.
local NO_HL = { "spell", "nospell", "conceal" }

---@param name string
---@return boolean
local function hl_has_color(name)
  local resolved = vim.api.nvim_get_hl(0, { name = name, link = true })
  return not vim.tbl_isempty(resolved)
end

--- Resolve a treesitter capture to a highlight group with color.
--- Prefers `@capture` (catppuccin defines most groups this way), falls back
--- to `@capture.lang` for captures that only have a lang-specific group
--- (e.g. `@markup.heading.1.markdown` → rainbow colors).
---@param cap table?
---@return string?
local function hl_for_capture(cap)
  if not cap then return nil end
  local without_lang = "@" .. cap.capture
  if hl_has_color(without_lang) then return without_lang end
  local with_lang = "@" .. cap.capture .. "." .. cap.lang
  if hl_has_color(with_lang) then return with_lang end
  return without_lang
end

---@param captures table[]
---@return table?
local function pick_capture(captures)
  for c = #captures, 1, -1 do
    local cap = captures[c]
    if cap and not vim.list_contains(NO_HL, cap.capture) then return cap end
  end
end

--- Walk `line` char-by-char, pushing {text, hl} chunks into `out`.
--- Uses `vim.fn.split(line, "\\zs")` so multi-byte UTF-8 chars (icons, CJK,
--- emoji) are kept whole — byte-wise `:sub(i, i)` would split them into
--- invalid sequences and render as `<e2><...>`.
---@param buf integer
---@param lnum integer 0-based
---@param line string
---@param out table
---@param offset? integer 0-based col offset for capture lookup
local function push_line(buf, lnum, line, out, offset)
  offset = offset or 0
  for i, char in ipairs(vim.fn.split(line, "\\zs")) do
    local cap = pick_capture(vim.treesitter.get_captures_at_pos(buf, lnum, offset + i - 1))
    table.insert(out, { char, cap and hl_for_capture(cap) or nil })
  end
end

--- Ensure the count-marker highlight group exists.
local function ensure_count_hl() vim.api.nvim_set_hl(0, COUNT_HL, { fg = "#000000", bg = "#66D9EF", italic = false }) end

---@return integer
local function fold_line_count() return vim.v.foldend - vim.v.foldstart end

--- Append the line-count marker chunk.
---@param out table
local function push_count_marker(out) table.insert(out, { " " .. COUNT_ICON .. fold_line_count() .. " ", COUNT_HL }) end

--- Append `.` fill to the end of the window.
---@param out table
local function push_dot_fill(out)
  local width = 0
  for _, chunk in ipairs(out) do
    width = width + vim.fn.strdisplaywidth(chunk[1])
  end
  local win_width = vim.fn.winwidth(0)
  if width < win_width then table.insert(out, { string.rep(".", win_width - width), "Folded" }) end
end

--- "bufline" algorithm: start line + count marker + end line, all with
--- treesitter highlights.
function M._bufline()
  ensure_count_hl()
  local buf = vim.api.nvim_get_current_buf()
  local start_line = vim.fn.getbufline(buf, vim.v.foldstart)[1] or ""
  local stop_line = vim.fn.getbufline(buf, vim.v.foldend)[1] or ""
  local out = {}

  push_line(buf, vim.v.foldstart - 1, start_line, out)

  push_count_marker(out)

  -- Skip leading whitespace of the end line.
  local ws = vim.fn.strchars(string.match(stop_line, "^%s*") or "")
  local trimmed = stop_line:sub(ws + 1)
  push_line(buf, vim.v.foldend - 1, trimmed, out, ws)

  push_dot_fill(out)
  return out
end

--- "regex" algorithm: start line + count marker + end line (only when the
--- end line matches a closing-symbol pattern). Original implementation.
function M._regex()
  ensure_count_hl()
  local buf = vim.api.nvim_get_current_buf()
  local start_text = vim.fn.getline(vim.v.foldstart):gsub("\t", string.rep(" ", vim.o.tabstop))
  local endline = vim.fn.getline(vim.v.foldend)
  local out = {}

  push_line(buf, vim.v.foldstart - 1, start_text, out)
  push_count_marker(out)

  for _, pattern in ipairs(CLOSE_PATTERNS) do
    if vim.trim(endline):find(pattern) == 1 then
      local offset = #(endline:match "^(%s+)" or "")
      push_line(buf, vim.v.foldend - 1, vim.trim(endline), out, offset)
      break
    end
  end

  push_dot_fill(out)
  return out
end

--- Entry point — dispatch by `M.algorithm`.
function M.foldtext()
  if M.algorithm == "regex" then return M._regex() end
  return M._bufline()
end

---@param opts? { algorithm?: "bufline" | "regex" }
function M.setup(opts)
  if opts and opts.algorithm then M.algorithm = opts.algorithm end
end

return M
