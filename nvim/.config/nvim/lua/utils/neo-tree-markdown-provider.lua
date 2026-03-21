-- Markdown provider for neo-tree document_symbols
-- This provides fallback support for markdown files when no LSP is available
-- Ported from outline.nvim's markdown provider

local M = {}

local kinds = require("neo-tree.sources.document_symbols.lib.kinds")

-- Parse markdown buffer and return symbol tree
---@param bufnr integer
---@param state neotree.StateWithTree
---@return neotree.SymbolNode[]
local function parse_markdown(bufnr, state)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local level_symbols = { { children = {} } }
  local max_level = 1
  local is_inside_code_block = false

  for line_num, value in ipairs(lines) do
    -- Toggle code block state
    if string.find(value, "^```") then
      is_inside_code_block = not is_inside_code_block
    end
    if is_inside_code_block then
      goto nextline
    end

    local next_value = lines[line_num + 1]
    local is_empty_line = #value:gsub("^%s*(.-)%s*$", "%1") == 0

    -- Check for standard headers (# Header)
    local header, title = string.match(value, "^(#+)%s+(.+)$")

    -- Check for underline headers (Header\n=== or Header\n---)
    if not header and next_value and not is_empty_line then
      if string.match(next_value, "^=+%s*$") then
        header = "#"
        title = value
      elseif string.match(next_value, "^-+%s*$") then
        header = "##"
        title = value
      end
    end

    if not header or not title then
      goto nextline
    end

    local depth = #header + 1

    -- Find parent
    local parent
    for i = depth - 1, 1, -1 do
      if level_symbols[i] ~= nil then
        parent = level_symbols[i].children
        break
      end
    end

    -- Clean up deeper level symbols
    for i = depth, max_level do
      if level_symbols[i] ~= nil then
        level_symbols[i].extra.selection_range["end"].line = line_num - 2
        level_symbols[i].extra.end_position[1] = line_num - 2
        level_symbols[i] = nil
      end
    end
    max_level = depth

    -- Create symbol node
    local entry = {
      id = tostring(line_num),
      name = title,
      type = "symbol",
      path = state.path,
      children = {},
      extra = {
        bufnr = bufnr,
        kind = kinds.get_kind(15), -- 15 is String in LSP, suitable for headers
        search_path = "/" .. title,
        selection_range = {
          start = { line_num - 1, 0 },
          ["end"] = { line_num - 1, 0 },
        },
        position = { line_num - 1, 0 },
        end_position = { line_num - 1, 0 },
      },
    }

    parent[#parent + 1] = entry
    level_symbols[depth] = entry

    ::nextline::
  end

  -- Finalize end positions for remaining symbols
  for i = 2, max_level do
    if level_symbols[i] ~= nil then
      level_symbols[i].extra.selection_range["end"].line = #lines - 1
      level_symbols[i].extra.end_position[1] = #lines - 1
    end
  end

  return level_symbols[1].children
end

-- Check if buffer is markdown
---@param bufnr integer
---@return boolean
function M.supports_buffer(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return ft == "markdown"
end

-- Render markdown symbols
---@param state neotree.StateWithTree
---@param callback function?
function M.render_symbols(state, callback)
  local bufnr = assert(state.lsp_bufnr, "document_symbols bufnr not set")
  local bufname = assert(state.path)

  local symbol_list = parse_markdown(bufnr, state)
  local splits = vim.split(bufname, "/")
  local filename = splits[#splits]

  local items = {
    {
      id = "0",
      name = string.format("SYMBOLS (markdown) in %s", filename),
      path = bufname,
      type = "root",
      children = symbol_list,
      extra = {
        kind = kinds.get_kind(0),
        search_path = "/",
      },
    },
  }

  local renderer = require("neo-tree.ui.renderer")
  renderer.show_nodes(items, state)

  if type(callback) == "function" then
    vim.schedule(callback)
  end
end

return M
