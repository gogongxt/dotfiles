-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "L3MON4D3/LuaSnip",
  config = function(plugin, opts)
    -- load snippets paths
    require("luasnip.loaders.from_vscode").load {
      paths = { vim.fn.stdpath "config" .. "/snippets" },
    }
    -- load Lua snippets
    require("luasnip.loaders.from_lua").load {
      paths = { vim.fn.stdpath "config" .. "/snippets" },
    }
    -- load snipmate snippets
    require("luasnip.loaders.from_snipmate").load {
      paths = { vim.fn.stdpath "config" .. "/snippets" },
    }
    -- include the default astronvim config that calls the setup call (must be last)
    require "astronvim.plugins.configs.luasnip"(plugin, opts)
  end,
}
