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
    },
    cmdline = {
      completion = {
        list = { selection = { preselect = true, auto_insert = true } },
        menu = { auto_show = true },
        ghost_text = { enabled = false },
      },
    },
  },
}
