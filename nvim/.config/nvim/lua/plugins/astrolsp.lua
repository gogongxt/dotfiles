-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      codelens = true, -- enable/disable codelens refresh on start
      inlay_hints = true, -- enable/disable inlay hints on start
      semantic_tokens = true, -- enable/disable semantic token highlighting
    },
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = false, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          -- "go",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 5000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- enable servers that you already have installed without mason
    servers = {
      -- use your own clangd in $PATH
      "clangd",
      -- "pyright"
    },
    -- customize language server configuration options passed to `lspconfig`
    ---@diagnostic disable: missing-fields
    config = {
      -- clangd = { capabilities = { offsetEncoding = "utf-8" } },
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              -- 不使用pycodestyle
              pycodestyle = { enabled = false },
            },
          },
        },
      },
      pyright = {
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              -- diagnosticMode = "workspace",
              typeCheckingMode = "off", -- here's me trying stuff
              useLibraryCodeForTypes = true,
              reportMissingModuleSource = "none", -- here's me trying stuff
              reportMissingImports = "none", -- here's me trying stuff
              reportUndefinedVariable = "none", -- here's me trying stuff, syntax errors are still reported on diagnostics
            },
          },
        },
      },
      basedpyright = {
        -- basedpyright config: https://docs.basedpyright.com/v1.23.1/configuration/language-server-settings/
        settings = {
          basedpyright = {
            analysis = {
              -- autoSearchPaths = true,
              -- diagnosticMode = "workspace",
              typeCheckingMode = "off", -- here's me trying stuff
              useLibraryCodeForTypes = true,
              diagnosticSeverityOverrides = {
                reportMissingModuleSource = "none", -- here's me trying stuff
                reportMissingImports = "none", -- here's me trying stuff
                reportUndefinedVariable = "none", -- here's me trying stuff, syntax errors are still reported on diagnostics
              },
            },
          },
        },
      },
    },
    -- customize how language servers are attached
    handlers = {
      -- a function without a key is simply the default handler, functions take two parameters, the server name and the configured options table for that server
      -- function(server, opts) require("lspconfig")[server].setup(opts) end

      -- the key is the server that is being setup with `lspconfig`
      -- rust_analyzer = false, -- setting a handler to false will disable the set up of that language server
      -- pyright = function(_, opts) require("lspconfig").pyright.setup(opts) end -- or a custom handler function can be passed
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
      lsp_codelens_refresh = {
        -- Optional condition to create/delete auto command group
        -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
        -- condition will be resolved for each client on each execution and if it ever fails for all clients,
        -- the auto commands will be deleted for that buffer
        cond = "textDocument/codeLens",
        -- cond = function(client, bufnr) return client.name == "lua_ls" end,
        -- list of auto commands to set
        {
          -- events to trigger
          event = { "InsertLeave", "BufEnter" },
          -- the rest of the autocmd options (:h nvim_create_autocmd)
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
          end,
        },
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        -- a `cond` key can provided as the string of a server capability to be required to attach, or a function with `client` and `bufnr` parameters from the `on_attach` that returns a boolean
        gh = {
          function() vim.lsp.buf.hover() end,
          desc = "Hover symbol details",
        },
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
        ["<Leader>lj"] = { vim.diagnostic.goto_next, desc = "Next Diagnostic", noremap = true, silent = true },
        ["<Leader>lk"] = { vim.diagnostic.goto_prev, desc = "Prev Diagnostic", noremap = true, silent = true },
        -- code action
        ["<Leader>la"] = {
          function() require("tiny-code-action").code_action() end,
          desc = "LSP code action",
          noremap = true,
          silent = true,
        },
      },
      x = {
        -- code action
        ["<Leader>la"] = {
          function() require("tiny-code-action").code_action() end,
          desc = "LSP code action",
          noremap = true,
          silent = true,
        },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    -- takes two parameters `client` and `bufnr`  (`:h lspconfig-setup`)
    on_attach = function(client, bufnr)
      -- this would disable semanticTokensProvider for all clients
      -- client.server_capabilities.semanticTokensProvider = nil
    end,
  },
}
