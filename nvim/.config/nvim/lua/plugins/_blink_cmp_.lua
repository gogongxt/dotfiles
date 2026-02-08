-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- astronvim default config:
-- $HOME/.local/share/astronvim_v5/lazy/AstroNvim/lua/astronvim/plugins/blink.lua
-- Document: https://cmp.saghen.dev/development/lsp-tracker.html

-- TODO: blink will support insertReplaceSupport soon

return {
  "Saghen/blink.cmp",
  opts = {
    completion = {
      list = { selection = { preselect = true, auto_insert = true } },
      menu = {
        auto_show = true,
      },
    },

    keymap = {
      ["<Tab>"] = { "accept", "fallback" },

      -- dap-repl: 菜单显示时用 blink 选择，未显示时用 dap-repl 历史记录
      ["<C-N>"] = {
        function(cmp)
          local ft = vim.api.nvim_buf_get_option(0, "filetype")
          local menu_visible = cmp.is_menu_visible()
          if ft == "dap-repl" and not menu_visible then
            vim.schedule(function() require("dap.repl").on_down() end)
            return true
          end
          local result = cmp.select_next()
          return result ~= nil
        end,
        "fallback_to_mappings",
      },
      ["<C-P>"] = {
        function(cmp)
          local ft = vim.api.nvim_buf_get_option(0, "filetype")
          local menu_visible = cmp.is_menu_visible()
          if ft == "dap-repl" and not menu_visible then
            vim.schedule(function() require("dap.repl").on_up() end)
            return true
          end
          local result = cmp.select_prev()
          return result ~= nil
        end,
        "fallback_to_mappings",
      },
    },
    cmdline = {
      completion = {
        list = { selection = { preselect = true, auto_insert = true } },
        menu = { auto_show = true },
        ghost_text = { enabled = false },
      },
      keymap = {
        -- ["<cr>"] = { "select_and_accept", "fallback" },
      },
    },
  },
}
