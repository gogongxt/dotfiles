-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["md"] = { "<cmd>MarkdownPreview<cr>", desc = "markdown preview" },
  },
  v = {},
}

--[[
===================== 📘 使用说明 =====================
SSH连接示例：
  ssh -R 7770:localhost:7770 -L 7771:127.0.0.1:7771 $USER@$IP -p $PORT
  端口映射说明：
    -R 7770:localhost:7770   ：远程端口7770 映射到本地7770，用于 Neovim 发送预览URL。
    -L 7771:127.0.0.1:7771   ：本地端口7771 映射到远程7771，用于浏览器访问预览页面。

🌍 环境变量设置：
  NVIM_MKDP_PORT=7771        # Markdown 预览服务器端口
  NVIM_MKDP_URL_PORT=7770    # 预览URL传输端口（同时用于 gx 打开链接）

🔗 功能说明：
  - Markdown 预览：由 markdown-preview.nvim 启动，URL 通过本地 socket 发送
  - gx 映射：光标处 URL 会被发送到本地监听的浏览器脚本 (同上端口)
======================================================
--]]
local mkdp_port = "0" -- default: auto port
if os.getenv "SSH_CONNECTION" ~= nil then
  mkdp_port = os.getenv "NVIM_MKDP_PORT" or "7771"
  local mkdp_url_port = os.getenv "NVIM_MKDP_URL_PORT" or "7770"

  -- 定义通用函数：发送 shell 命令到本地端口执行
  vim.api.nvim_exec(
    [[
    function! SendCmdToLocalhost(cmd, port)
      " 使用环境变量传递命令，避免 shell 转义问题
      let $SSH_CMD = a:cmd
      call system("python3 -c \"import socket,os; s=socket.socket(); s.connect(('localhost'," . a:port . ")); s.send(('CMD:' + os.environ['SSH_CMD']).encode()); s.close()\" &")
    endfunction
    function! SendUrlToLocalhost(url, port)
      let l:url = substitute(a:url, '0\.0\.0\.0', 'localhost', 'g')
      call SendCmdToLocalhost('open ' . shellescape(l:url), a:port)
    endfunction
  ]],
    false
  )

  -- gx 映射（发送当前URL到相同端口）
  vim.cmd(string.format(
    [[
    function! OpenLinkWithLocalBrowser()
      let l:url = expand('<cfile>')
      if l:url !~? '^https\?://'
        lua vim.notify("⚠️ Not a valid URL under cursor", vim.log.levels.WARN)
        return
      endif
      call SendUrlToLocalhost(l:url, %s)
      lua vim.notify("🔗 Sent to local browser: " .. vim.fn.expand('<cfile>'), vim.log.levels.INFO)
    endfunction
    nnoremap gx :call OpenLinkWithLocalBrowser()<CR>
  ]],
    mkdp_url_port
  ))
end

return {
  {
    "selimacerbas/markdown-preview.nvim",
    dependencies = { "selimacerbas/live-server.nvim" },
    config = function()
      require("markdown_preview").setup {
        -- all optional; sane defaults shown
        instance_mode = "takeover", -- "takeover" (one tab) or "multi" (tab per instance)
        port = tonumber(mkdp_port),
        open_browser = os.getenv "SSH_CONNECTION" == nil, -- only auto-open in local mode
        debounce_ms = 300,
      }
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" }, -- if you use standalone mini plugins
    -- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    config = function()
      local function set_render_markdown_highlights()
        vim.cmd [[highlight RenderMarkdownDash guifg=#D19A66 ]]
        vim.cmd [[highlight RenderMarkdownCode guibg=#4a4f66 ]]
      end
      -- 初次设置
      set_render_markdown_highlights()
      -- colorscheme 切换时重新设置
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_render_markdown_highlights,
        desc = "Override render-markdown highlights",
      })

      require("render-markdown").setup {
        -- Whether Markdown should be rendered by default or not
        enabled = true,
        -- Vim modes that will show a rendered view of the markdown file, :h mode(), for
        -- all enabled components. Individual components can be enabled for other modes.
        -- Remaining modes will be unaffected by this plugin.
        -- render_modes = { "n", "c", "t" },
        render_modes = true, -- Always render regardless of current mode
        -- Maximum file size (in MB) that this plugin will attempt to render
        -- Any file larger than this will effectively be ignored
        max_file_size = 10.0,
        -- Milliseconds that must pass before updating marks, updates occur
        -- within the context of the visible window, not the entire buffer
        debounce = 100,
        -- Pre configured settings that will attempt to mimic various target
        -- user experiences. Any user provided settings will take precedence.
        --  obsidian: mimic Obsidian UI
        --  lazy:     will attempt to stay up to date with LazyVim configuration
        --  none:     does nothing
        preset = "none",
        -- The level of logs to write to file: vim.fn.stdpath('state') .. '/render-markdown.log'
        -- Only intended to be used for plugin development / debugging
        log_level = "error",
        -- Print runtime of main update method
        -- Only intended to be used for plugin development / debugging
        log_runtime = false,
        -- Filetypes this plugin will run on
        file_types = { "markdown" },
        -- Out of the box language injections for known filetypes that allow markdown to be
        -- interpreted in specified locations, see :h treesitter-language-injections
        -- Set enabled to false in order to disable
        injections = {
          gitcommit = {
            enabled = true,
            query = [[
                ((message) @injection.content
                    (#set! injection.combined)
                    (#set! injection.include-children)
                    (#set! injection.language "markdown"))
            ]],
          },
        },
        padding = {
          -- Highlight to use when adding whitespace, should match background
          highlight = "Normal",
        },
        latex = {
          -- Whether LaTeX should be rendered, mainly used for health check
          enabled = false,
        },
        on = {
          -- Called when plugin initially attaches to a buffer
          attach = function() end,
          -- Called after plugin renders a buffer
          render = function() end,
        },
        heading = {
          -- Turn on / off heading icon & background rendering
          enabled = true,
          -- Additional modes to render headings
          render_modes = true,
          -- Turn on / off any sign column related rendering
          sign = true,
          -- Replaces '#+' of 'atx_h._marker'
          -- The number of '#' in the heading determines the 'level'
          -- The 'level' is used to index into the list using a cycle
          -- If the value is a function the input is the nesting level of the heading within sections
          icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
          -- Determines how icons fill the available space:
          --  right:   '#'s are concealed and icon is appended to right side
          --  inline:  '#'s are concealed and icon is inlined on left side
          --  overlay: icon is left padded with spaces and inserted on left hiding any additional '#'
          position = "overlay",
          -- Added to the sign column if enabled
          -- The 'level' is used to index into the list using a cycle
          signs = { "󰫎 " },
          -- Width of the heading background:
          --  block: width of the heading text
          --  full:  full width of the window
          -- Can also be a list of the above values in which case the 'level' is used
          -- to index into the list using a clamp
          width = "full",
          -- Amount of margin to add to the left of headings
          -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
          -- Margin available space is computed after accounting for padding
          -- Can also be a list of numbers in which case the 'level' is used to index into the list using a clamp
          left_margin = 0,
          -- Amount of padding to add to the left of headings
          -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
          -- Can also be a list of numbers in which case the 'level' is used to index into the list using a clamp
          left_pad = 0,
          -- Amount of padding to add to the right of headings when width is 'block'
          -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
          -- Can also be a list of numbers in which case the 'level' is used to index into the list using a clamp
          right_pad = 0,
          -- Minimum width to use for headings when width is 'block'
          -- Can also be a list of integers in which case the 'level' is used to index into the list using a clamp
          min_width = 0,
          -- Determines if a border is added above and below headings
          -- Can also be a list of booleans in which case the 'level' is used to index into the list using a clamp
          border = true,
          -- Always use virtual lines for heading borders instead of attempting to use empty lines
          border_virtual = false,
          -- Highlight the start of the border using the foreground highlight
          border_prefix = false,
          -- Used above heading for border
          above = "▄",
          -- Used below heading for border
          below = "▀",
          -- The 'level' is used to index into the list using a clamp
          -- Highlight for the heading icon and extends through the entire line
          backgrounds = {
            "RenderMarkdownH1Bg",
            "RenderMarkdownH2Bg",
            "RenderMarkdownH3Bg",
            "RenderMarkdownH4Bg",
            "RenderMarkdownH5Bg",
            "RenderMarkdownH6Bg",
          },
          -- The 'level' is used to index into the list using a clamp
          -- Highlight for the heading and sign icons
          foregrounds = {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
          },
        },
        paragraph = {
          -- Turn on / off paragraph rendering
          enabled = true,
          -- Additional modes to render paragraphs
          render_modes = true,
          -- Amount of margin to add to the left of paragraphs
          -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
          left_margin = 0,
          -- Minimum width to use for paragraphs
          min_width = 0,
        },
        dash = {
          -- Turn on / off thematic break rendering
          enabled = true,
          -- Additional modes to render dash
          render_modes = true,
          -- Replaces '---'|'***'|'___'|'* * *' of 'thematic_break'
          -- The icon gets repeated across the window's width
          -- icon = "─",
          icon = "-",
          -- Width of the generated line:
          --  <number>: a hard coded width value, if a floating point value < 1 is provided it is
          --            treated as a percentage of the available window space
          --  full:     full width of the window
          width = "full",
          -- Amount of margin to add to the left of dash
          -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
          left_margin = 0,
          -- Highlight for the whole line generated from the icon
          highlight = "RenderMarkdownDash",
        },
        -- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'
        -- There are two special states for unchecked & checked defined in the markdown grammar
        checkbox = {
          -- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'.
          -- There are two special states for unchecked & checked defined in the markdown grammar.
          -- Turn on / off checkbox state rendering.
          enabled = true,
          -- Additional modes to render checkboxes.
          render_modes = false,
          -- Render the bullet point before the checkbox.
          bullet = false,
          -- Padding to add to the right of checkboxes.
          right_pad = 1,
          unchecked = {
            -- Replaces '[ ]' of 'task_list_marker_unchecked'.
            icon = "󰄱 ",
            -- Highlight for the unchecked icon.
            highlight = "RenderMarkdownUnchecked",
            -- Highlight for item associated with unchecked checkbox.
            scope_highlight = nil,
          },
          checked = {
            -- Replaces '[x]' of 'task_list_marker_checked'.
            icon = "󰱒 ",
            -- Highlight for the checked icon.
            highlight = "RenderMarkdownChecked",
            -- Highlight for item associated with checked checkbox.
            scope_highlight = nil,
          },
          -- Define custom checkbox states, more involved, not part of the markdown grammar.
          -- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks.
          -- The key is for healthcheck and to allow users to change its values, value type below.
          -- | raw             | matched against the raw text of a 'shortcut_link'           |
          -- | rendered        | replaces the 'raw' value when rendering                     |
          -- | highlight       | highlight for the 'rendered' icon                           |
          -- | scope_highlight | optional highlight for item associated with custom checkbox |
          -- stylua: ignore
          custom = {
            todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo', scope_highlight = nil },
          },
        },
        quote = {
          -- Turn on / off block quote & callout rendering
          enabled = true,
          -- Additional modes to render quotes
          render_modes = true,
          -- Replaces '>' of 'block_quote'
          icon = "▋",
          -- Whether to repeat icon on wrapped lines. Requires neovim >= 0.10. This will obscure text if
          -- not configured correctly with :h 'showbreak', :h 'breakindent' and :h 'breakindentopt'. A
          -- combination of these that is likely to work is showbreak = '  ' (2 spaces), breakindent = true,
          -- breakindentopt = '' (empty string). These values are not validated by this plugin. If you want
          -- to avoid adding these to your main configuration then set them in win_options for this plugin.
          repeat_linebreak = false,
          -- Highlight for the quote icon
          highlight = "RenderMarkdownQuote",
        },
        pipe_table = {
          -- Turn on / off pipe table rendering
          enabled = true,
          -- Additional modes to render pipe tables
          render_modes = true,
          -- Pre configured settings largely for setting table border easier
          --  heavy:  use thicker border characters
          --  double: use double line border characters
          --  round:  use round border corners
          --  none:   does nothing
          preset = "none",
          -- Determines how the table as a whole is rendered:
          --  none:   disables all rendering
          --  normal: applies the 'cell' style rendering to each row of the table
          --  full:   normal + a top & bottom line that fill out the table when lengths match
          style = "full",
          -- Determines how individual cells of a table are rendered:
          --  overlay: writes completely over the table, removing conceal behavior and highlights
          --  raw:     replaces only the '|' characters in each row, leaving the cells unmodified
          --  padded:  raw + cells are padded to maximum visual width for each column
          --  trimmed: padded except empty space is subtracted from visual width calculation
          cell = "padded",
          -- Amount of space to put between cell contents and border
          padding = 1,
          -- Minimum column width to use for padded or trimmed cell
          min_width = 0,
          -- Characters used to replace table border
          -- Correspond to top(3), delimiter(3), bottom(3), vertical, & horizontal
          -- stylua: ignore
          border = {
            '┌', '┬', '┐',
            '├', '┼', '┤',
            '└', '┴', '┘',
            '│', '─',
          },
          -- Gets placed in delimiter row for each column, position is based on alignment
          alignment_indicator = "━",
          -- Highlight for table heading, delimiter, and the line above
          head = "RenderMarkdownTableHead",
          -- Highlight for everything else, main table rows and the line below
          row = "RenderMarkdownTableRow",
          -- Highlight for inline padding used to add back concealed space
          filler = "RenderMarkdownTableFill",
        },
        -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'
        -- Can specify as many additional values as you like following the pattern from any below, such as 'note'
        --   The key in this case 'note' is for healthcheck and to allow users to change its values
        --   'raw':        Matched against the raw text of a 'shortcut_link', case insensitive
        --   'rendered':   Replaces the 'raw' value when rendering
        --   'highlight':  Highlight for the 'rendered' text and quote markers
        --   'quote_icon': Optional override for quote.icon value for individual callout
        callout = {
          note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
          tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
          important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
          warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
          caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
          -- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
          abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
          summary = { raw = "[!SUMMARY]", rendered = "󰨸 Summary", highlight = "RenderMarkdownInfo" },
          tldr = { raw = "[!TLDR]", rendered = "󰨸 Tldr", highlight = "RenderMarkdownInfo" },
          info = { raw = "[!INFO]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
          todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
          hint = { raw = "[!HINT]", rendered = "󰌶 Hint", highlight = "RenderMarkdownSuccess" },
          success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
          check = { raw = "[!CHECK]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
          done = { raw = "[!DONE]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
          question = { raw = "[!QUESTION]", rendered = "󰘥 Question", highlight = "RenderMarkdownWarn" },
          help = { raw = "[!HELP]", rendered = "󰘥 Help", highlight = "RenderMarkdownWarn" },
          faq = { raw = "[!FAQ]", rendered = "󰘥 Faq", highlight = "RenderMarkdownWarn" },
          attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownWarn" },
          failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
          fail = { raw = "[!FAIL]", rendered = "󰅖 Fail", highlight = "RenderMarkdownError" },
          missing = { raw = "[!MISSING]", rendered = "󰅖 Missing", highlight = "RenderMarkdownError" },
          danger = { raw = "[!DANGER]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
          error = { raw = "[!ERROR]", rendered = "󱐌 Error", highlight = "RenderMarkdownError" },
          bug = { raw = "[!BUG]", rendered = "󰨰 Bug", highlight = "RenderMarkdownError" },
          example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
          quote = { raw = "[!QUOTE]", rendered = "󱆨 Quote", highlight = "RenderMarkdownQuote" },
          cite = { raw = "[!CITE]", rendered = "󱆨 Cite", highlight = "RenderMarkdownQuote" },
        },
        link = {
          -- Turn on / off inline link icon rendering
          enabled = true,
          -- Additional modes to render links
          render_modes = true,
          -- How to handle footnote links, start with a '^'
          footnote = {
            -- Replace value with superscript equivalent
            superscript = true,
            -- Added before link content when converting to superscript
            prefix = "",
            -- Added after link content when converting to superscript
            suffix = "",
          },
          -- Inlined with 'image' elements
          image = "󰥶 ",
          -- Inlined with 'email_autolink' elements
          email = "󰀓 ",
          -- Fallback icon for 'inline_link' and 'uri_autolink' elements
          hyperlink = "󰌹 ",
          -- Applies to the inlined icon as a fallback
          highlight = "RenderMarkdownLink",
          -- Applies to WikiLink elements
          wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" },
          -- Define custom destination patterns so icons can quickly inform you of what a link
          -- contains. Applies to 'inline_link', 'uri_autolink', and wikilink nodes. When multiple
          -- patterns match a link the one with the longer pattern is used.
          -- Can specify as many additional values as you like following the 'web' pattern below
          --   The key in this case 'web' is for healthcheck and to allow users to change its values
          --   'pattern':   Matched against the destination text see :h lua-pattern
          --   'icon':      Gets inlined before the link text
          --   'highlight': Optional highlight for the 'icon', uses fallback highlight if not provided
          custom = {
            web = { pattern = "^http", icon = "󰖟 " },
            youtube = { pattern = "youtube%.com", icon = "󰗃 " },
            github = { pattern = "github%.com", icon = "󰊤 " },
            neovim = { pattern = "neovim%.io", icon = " " },
            stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
            discord = { pattern = "discord%.com", icon = "󰙯 " },
            reddit = { pattern = "reddit%.com", icon = "󰑍 " },
          },
        },
        sign = {
          -- Turn on / off sign rendering
          enabled = false,
          -- Applies to background of sign text
          highlight = "RenderMarkdownSign",
        },
        -- Mimics Obsidian inline highlights when content is surrounded by double equals
        -- The equals on both ends are concealed and the inner content is highlighted
        inline_highlight = {
          -- Turn on / off inline highlight rendering
          enabled = true,
          -- Additional modes to render inline highlights
          render_modes = true,
          -- Applies to background of surrounded text
          highlight = "RenderMarkdownInlineHighlight",
        },
        -- Mimic org-indent-mode behavior by indenting everything under a heading based on the
        -- level of the heading. Indenting starts from level 2 headings onward.
        indent = {
          -- Turn on / off org-indent-mode
          enabled = false,
          -- Additional modes to render indents
          render_modes = true,
          -- Amount of additional padding added for each heading level
          per_level = 2,
          -- Heading levels <= this value will not be indented
          -- Use 0 to begin indenting from the very first level
          skip_level = 1,
          -- Do not indent heading titles, only the body
          skip_heading = false,
        },
        html = {
          -- Turn on / off all HTML rendering
          enabled = true,
          -- Additional modes to render HTML
          render_modes = true,
          comment = {
            -- Turn on / off HTML comment concealing
            conceal = true,
            -- Optional text to inline before the concealed comment
            text = nil,
            -- Highlight for the inlined text
            highlight = "RenderMarkdownHtmlComment",
          },
        },
        -- Window options to use that change between rendered and raw view
        win_options = {
          -- See :h 'conceallevel'
          conceallevel = {
            -- Used when not being rendered, get user setting
            default = vim.api.nvim_get_option_value("conceallevel", {}),
            -- Used when being rendered, concealed text is completely hidden
            rendered = 3,
          },
          -- See :h 'concealcursor'
          concealcursor = {
            -- Used when not being rendered, get user setting
            default = vim.api.nvim_get_option_value("concealcursor", {}),
            -- Used when being rendered, disable concealing text in all modes
            rendered = "",
          },
        },
        -- More granular configuration mechanism, allows different aspects of buffers
        -- to have their own behavior. Values default to the top level configuration
        -- if no override is provided. Supports the following fields:
        --   enabled, max_file_size, debounce, render_modes, anti_conceal, padding,
        --   heading, paragraph, code, dash, bullet, checkbox, quote, pipe_table,
        --   callout, link, sign, indent, latex, html, win_options
        overrides = {
          -- Overrides for different buftypes, see :h 'buftype'
          buftype = {
            nofile = {
              padding = { highlight = "NormalFloat" },
              sign = { enabled = false },
            },
          },
          -- Overrides for different filetypes, see :h 'filetype'
          filetype = {},
        },
        -- Mapping from treesitter language to user defined handlers
        -- See 'Custom Handlers' document for more info
        custom_handlers = {},
      }
    end,
  },
}
