-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "Wansmer/symbol-usage.nvim",
    event = "BufReadPre", -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
    config = function()
      local function h(name) return vim.api.nvim_get_hl(0, { name = name }) end

      -- hl-groups can have any name
      vim.api.nvim_set_hl(0, "SymbolUsageRounding", { fg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageContent", { bg = h("CursorLine").bg, fg = h("Comment").fg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageRef", { fg = h("Function").fg, bg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageDef", { fg = h("Type").fg, bg = h("CursorLine").bg, italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageImpl", { fg = h("@keyword").fg, bg = h("CursorLine").bg, italic = true })

      local function text_format(symbol)
        local res = {}

        local round_start = { "", "SymbolUsageRounding" }
        local round_end = { "", "SymbolUsageRounding" }

        -- Indicator that shows if there are any other symbols in the same line
        local stacked_functions_content = symbol.stacked_count > 0 and ("+%s"):format(symbol.stacked_count) or ""

        if symbol.references then
          local usage = symbol.references <= 1 and "usage" or "usages"
          local num = symbol.references == 0 and "no" or symbol.references
          table.insert(res, round_start)
          table.insert(res, { "󰌹 ", "SymbolUsageRef" })
          table.insert(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        if symbol.definition then
          if #res > 0 then table.insert(res, { " ", "NonText" }) end
          table.insert(res, round_start)
          table.insert(res, { "󰳽 ", "SymbolUsageDef" })
          table.insert(res, { symbol.definition .. " defs", "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        if symbol.implementation then
          if #res > 0 then table.insert(res, { " ", "NonText" }) end
          table.insert(res, round_start)
          table.insert(res, { "󰡱 ", "SymbolUsageImpl" })
          table.insert(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        if stacked_functions_content ~= "" then
          if #res > 0 then table.insert(res, { " ", "NonText" }) end
          table.insert(res, round_start)
          table.insert(res, { " ", "SymbolUsageImpl" })
          table.insert(res, { stacked_functions_content, "SymbolUsageContent" })
          table.insert(res, round_end)
        end

        return res
      end

      local SymbolKind = vim.lsp.protocol.SymbolKind
      ---@type UserOpts
      require("symbol-usage").setup {
        ---@type table<string, any> `nvim_set_hl`-like options for highlight virtual text
        hl = { link = "Comment" },
        ---@type lsp.SymbolKind[] Symbol kinds what need to be count (see `lsp.SymbolKind`)
        kinds = { SymbolKind.Function, SymbolKind.Method, SymbolKind.Class, SymbolKind.Struct },
        ---Additional filter for kinds. Recommended use in the filetypes override table.
        ---fiterKind: function(data: { symbol:table, parent:table, bufnr:integer }): boolean
        ---`symbol` and `parent` is an item from `textDocument/documentSymbol` request
        ---See: #filter-kinds
        ---@type table<lsp.SymbolKind, filterKind[]>
        kinds_filter = {},
        ---@type 'above'|'end_of_line'|'textwidth'|'signcolumn' `above` by default
        vt_position = "end_of_line",
        vt_priority = nil, ---@type integer Virtual text priority (see `nvim_buf_set_extmark`)
        ---Text to display when request is pending. If `false`, extmark will not be
        ---created until the request is finished. Recommended to use with `above`
        ---vt_position to avoid "jumping lines".
        ---@type string|table|false
        request_pending_text = "loading...",
        ---The function can return a string to which the highlighting group from `opts.hl` is applied.
        ---Alternatively, it can return a table of tuples of the form `{ { text, hl_group }, ... }`` - in this case the specified groups will be applied.
        ---If `vt_position` is 'signcolumn', then only a 1-2 length string or a `{{ icon, hl_group }}` table is expected.
        ---See `#format-text-examples`
        ---@type function(symbol: Symbol): string|table Symbol{ definition = integer|nil, implementation = integer|nil, references = integer|nil, stacked_count = integer, stacked_symbols = table<SymbolId, Symbol> }
        text_format = text_format,
        references = { enabled = true, include_declaration = false },
        definition = { enabled = false },
        implementation = { enabled = false },
        ---@type { lsp?: string[], filetypes?: string[], cond?: function[] } Disables `symbol-usage.nvim' for specific LSPs, filetypes, or on custom conditions.
        ---The function in the `cond` list takes an argument `bufnr` and returns a boolean. If it returns true, `symbol-usage` will not run in that buffer.
        disable = { lsp = {}, filetypes = {}, cond = {} },
        ---@type UserOpts[] See default overridings in `lua/symbol-usage/langs.lua`
        -- filetypes = {},
        ---@type 'start'|'end' At which position of `symbol.selectionRange` the request to the lsp server should start. Default is `end` (try changing it to `start` if the symbol counting is not correct).
        symbol_request_pos = "end", -- Recommended redefine only in `filetypes` override table
        ---@type (fun(ctx: lsp.HandlerContext):fun(symbol: lsp.Location): boolean)?
        -- This is a function factory that takes the LSP context as a parameter and
        -- produce a filter function for vim.tbl_filter. This can be used to exclude
        -- certain references/definition/implementation from being included in the
        -- count. See [Filtering Symbols] for details.
        symbol_filter = nil,
        ---@type LoggerConfig
        log = { enabled = false },
      }
    end,
  },
}
