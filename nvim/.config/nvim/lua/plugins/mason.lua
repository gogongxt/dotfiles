-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        --format for many file types
        --angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml
        "prettier",

        -- lsp
        "lua-language-server",
        "stylua",
        "selene",

        -- install any other package
        "tree-sitter-cli",

        -- python
        -- "pyright",
        "basedpyright",
        "black",
        "isort",
        -- "debugpy",

        -- bash
        "bash-language-server",
        "shfmt",
        "shellcheck", -- bashls use with shellcheck for Linter

        -- cmake
        "neocmakelsp",
        "cmakelang",

        -- toml
        "taplo",
      },
    },
  },
}
