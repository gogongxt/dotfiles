-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Custom DAP Breakpoints Picker
---@param opts snacks.picker.Config
---@type snacks.picker.finder
local function dap_breakpoints_finder(opts, ctx)
  local ok, breakpoints = pcall(function() return require("dap.breakpoints").get() end)
  if not ok then
    vim.notify("DAP not available", vim.log.levels.WARN)
    return ctx.filter:filter {}
  end
  local items = {} ---@type snacks.picker.finder.Item[]
  for bufnr, buf_bps in pairs(breakpoints) do
    local file = vim.api.nvim_buf_get_name(bufnr)
    for _, bp in ipairs(buf_bps) do
      local state = bp.state or {}
      local verified = not state.verified and "✗" or "✓"
      -- Get line content for display
      local line_content = ""
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local lines = vim.api.nvim_buf_get_lines(bufnr, bp.line - 1, bp.line, false)
        line_content = lines[1] or ""
      end
      -- Build info string
      local info_parts = {}
      -- if not state.verified then
      --   table.insert(info_parts, state.message and "Rejected: " .. state.message or "Rejected")
      -- end
      if bp.logMessage then table.insert(info_parts, "Log: " .. bp.logMessage) end
      if bp.condition then table.insert(info_parts, "Cond: " .. bp.condition) end
      if bp.hitCondition then table.insert(info_parts, "Hit: " .. bp.hitCondition) end
      local info = #info_parts > 0 and "[" .. table.concat(info_parts, ", ") .. "]" or ""
      table.insert(items, {
        file = file,
        -- DON'T set buf field, so preview reads file content instead of opening buffer
        pos = { bp.line, 0 },
        line = line_content, -- line should be string content, not line number
        text = file .. ":" .. bp.line .. ":" .. line_content, -- same format as grep for searching
        comment = info ~= "" and info or nil, -- use comment field for additional info, use nil to avoid extra space
        label = verified, -- show verified status as label
        breakpoint_data = bp,
      })
    end
  end
  return ctx.filter:filter(items)
end

return {
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          -- ["<Leader>fs"] = { function() require("snacks").picker.smart() end, desc = "Find buffers/recent/files" },
          ["<Leader>fs"] = { function() require("snacks").picker.grep { regex = false } end, desc = "Find string" },
          ["<Leader>fS"] = {
            function() require("snacks").picker.grep { regex = false, hidden = true, ignored = true } end,
            desc = "Find string in all files",
          },
          ["<Leader>fw"] = {
            function() require("snacks").picker.grep_word { args = {}, regex = false, live = true } end,
            desc = "Find words",
          },
          ["<Leader>fW"] = {
            function()
              require("snacks").picker.grep_word { args = {}, regex = false, live = true, hidden = true, ignored = true }
            end,
            desc = "Find words in all files",
          },
          ["<Leader>fr"] = { function() require("snacks").picker.recent() end, desc = "Find recent files" },
          ["<Leader>fR"] = {
            function() require("snacks").picker.recent { filter = { cwd = true } } end,
            desc = "Find old files (cwd)",
          },
          ["<Leader>fp"] = { function() require("snacks").picker.projects() end, desc = "Find projects" },
          ["<Leader>fy"] = { function() require("snacks").picker.registers() end, desc = "Find registers" },
          ["<Leader>fn"] = { "<cmd>Noice pick<cr>", desc = "Find themes" },
          ["<Leader>fc"] = { function() require("snacks").picker.command_history() end, desc = "Find commands history" },
          ["<Leader>fC"] = { function() require("snacks").picker.commands() end, desc = "Find all commands" },
          ["<Leader>ut"] = { function() require("snacks").picker.colorschemes() end, desc = "Find themes" },
          ["<Leader>fT"] = {
            function()
              if not package.loaded["todo-comments"] then -- make sure to load todo-comments
                require("lazy").load { plugins = { "todo-comments.nvim" } }
              end
              require("snacks").picker.todo_comments { keywords = { "TODO" } }
            end,
            desc = "Find TODO",
          },
          ["<Leader>ft"] = {
            function()
              if not package.loaded["todo-comments"] then -- make sure to load todo-comments
                require("lazy").load { plugins = { "todo-comments.nvim" } }
              end
              require("snacks").picker.todo_comments()
            end,
            desc = "Find ALL TODO FIXME NOTE...",
          },
          ["<Leader>fd"] = { function() require("snacks").picker.dap_breakpoints() end, desc = "Find DAP breakpoints" },
        },
        v = {
          ["<Leader>fw"] = {
            function() require("snacks").picker.grep_word { args = {}, regex = false, live = true } end,
            desc = "Find words",
          },
          ["<Leader>fW"] = {
            function()
              require("snacks").picker.grep_word { args = {}, regex = false, live = true, hidden = true, ignored = true }
            end,
            desc = "Find words in all files",
          },
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Custom source for DAP breakpoints
        sources = {
          dap_breakpoints = {
            finder = dap_breakpoints_finder,
            format = "file",
            preview = "file",
            matcher = { fuzzy = false }, -- use fuzzy matching like grep
          },
        },
        toggles = {
          regex = { icon = "R", value = true }, -- R键表示启用正则表达式
          exclude_icon = { icon = "!Exc", value = true }, -- E键表示启用exclude
          exclude_docs_icon = { icon = "!Docs", value = true }, -- D键表示启用文档排除
        },
        actions = {
          cycle_preview_layout = function(picker)
            -- 获取当前外层 box 方向（"horizontal"=预览在右，"vertical"=预览在下）
            local current_box = picker.resolved_layout.layout and picker.resolved_layout.layout.box
            -- horizontal <-> vertical 切换
            local next_box = (current_box == "horizontal") and "vertical" or "horizontal"
            picker:set_layout {
              layout = {
                box = next_box,
                width = 0.8,
                min_width = 120,
                height = 0.8,
                {
                  box = "vertical",
                  border = true,
                  title = "{title} {live} {flags}",
                  { win = "input", height = 1, border = "bottom" },
                  { win = "list", border = "none" },
                },
                {
                  win = "preview",
                  title = "{preview}",
                  border = true,
                  width = (next_box == "horizontal") and 0.5 or nil,
                  height = (next_box == "vertical") and 0.5 or nil,
                },
              },
            }
          end,
          toggle_exclude = function(picker)
            -- 在picker源码grep中是这样处理exclude的
            -- for _, e in ipairs(opts.exclude or {}) do
            --   vim.list_extend(args, { "-g", "!" .. e })
            -- end
            if not picker._exclude then
              picker._exclude = true
              picker.opts.exclude = picker.opts.exclude or {}
              table.insert(picker.opts.exclude, "3rdparty/**")
              table.insert(picker.opts.exclude, "**test**")
              table.insert(picker.opts.exclude, "benchmark/**")
              table.insert(picker.opts.exclude, "examples/**")
              picker.opts.exclude_icon = true
              vim.notify("Add exclude ( 3rdparty/, **test**, benchmark/, examples/ )", vim.log.levels.INFO)
            else
              picker._exclude = false
              picker.opts.exclude = {}
              picker.opts.exclude_icon = false
              vim.notify("Show all files", vim.log.levels.INFO)
            end
            picker.list:set_target()
            picker:find()
          end,
          toggle_docs = function(picker)
            if not picker._exclude_docs then
              picker._exclude_docs = true
              picker.opts.exclude = picker.opts.exclude or {}
              table.insert(picker.opts.exclude, "doc/**")
              table.insert(picker.opts.exclude, "docs/**")
              table.insert(picker.opts.exclude, "**/*.md")
              table.insert(picker.opts.exclude, "**/*.txt")
              table.insert(picker.opts.exclude, "**/*.rst")
              picker.opts.exclude_docs_icon = true
              vim.notify("Exclude docs ( doc/, docs/, *.md, *.txt, *.rst )", vim.log.levels.INFO)
            else
              picker._exclude_docs = false
              picker.opts.exclude = {}
              picker.opts.exclude_docs_icon = false
              vim.notify("Include docs files", vim.log.levels.INFO)
            end
            picker.list:set_target()
            picker:find()
          end,
        },
        win = {
          input = {
            keys = {
              ["<C-j>"] = { "history_forward", mode = { "i", "n" } },
              ["<C-k>"] = { "history_back", mode = { "i", "n" } },
              ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
              ["<a-s-p>"] = { "cycle_preview_layout", mode = { "i", "n" } },
              ["<a-r>"] = { "toggle_regex", mode = { "i", "n" } },
              ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
              ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
              ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
              ["\\"] = { "edit_vsplit", mode = { "n" } },
              ["<c-\\>"] = { "edit_vsplit", mode = { "i", "n" } },
              ["-"] = { "edit_split", mode = { "n" } },
              ["<C-_>"] = { "edit_split", mode = { "i", "n" } },
              ["<a-e>"] = { "toggle_exclude", mode = { "i", "n" } },
              ["<a-d>"] = { "toggle_docs", mode = { "i", "n" } },
              -- ["<c-->"] = { "edit_split", mode = { "i", "n" } }, -- cannot map ctrl--
            },
          },
        },
      },
      scroll = {
        enabled = true,
      },
      notifier = {
        enabled = false,
      },
      image = {
        enabled = os.getenv "SSH_CONNECTION" == nil,
        -- TODO: need to toggle doc image show inline
        -- https://github.com/folke/snacks.nvim/issues/1739
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = true,
          max_width = 80,
          max_height = 40,
          -- Set to `true`, to conceal the image text when rendering inline.
          -- (experimental)
          ---@param lang string tree-sitter language
          ---@param type snacks.image.Type image type
          conceal = function(lang, type)
            -- only conceal math expressions
            return type == "math"
          end,
        },
      },
      -- input = {
      --   enabled = true,
      -- },
      -- zen = {
      --   toggles = {
      --     dim = false,
      --     git_signs = true,
      --     mini_diff_signs = true,
      --     diagnostics = true,
      --     inlay_hints = true,
      --   },
      --   show = {
      --     statusline = true, -- can only be shown when using the global statusline
      --     tabline = true,
      --   },
      --   ---@type snacks.win.Config
      --   win = { style = "zen" },
      --   --- Callback when the window is opened.
      --   ---@param win snacks.win
      --   on_open = function(win) end,
      --   --- Callback when the window is closed.
      --   ---@param win snacks.win
      --   on_close = function(win) end,
      --   --- Options for the `Snacks.zen.zoom()`
      --   ---@type snacks.zen.Config
      --   zoom = {
      --     toggles = {},
      --     show = { statusline = true, tabline = true },
      --     win = {
      --       backdrop = false,
      --       width = 0, -- full width
      --     },
      --   },
      -- },
    },
  },
}
