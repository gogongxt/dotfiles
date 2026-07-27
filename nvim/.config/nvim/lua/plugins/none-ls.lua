-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    -- opts variable is the default configuration table for the setup function call
    -- local null_ls = require "null-ls"

    -- Check supported formatters and linters
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics

    local nls = require "null-ls"
    local h = require "null-ls.helpers"

    -- none-ls 没有内置 dockerfmt 源，这里用 make_builtin 自己封装一个
    -- (dockerfmt: https://github.com/reteps/dockerfmt)
    local dockerfmt = h.make_builtin {
      name = "dockerfmt",
      meta = {
        url = "https://github.com/reteps/dockerfmt",
        description = "Format Dockerfiles and shell commands within RUN steps.",
      },
      method = nls.methods.FORMATTING,
      filetypes = { "dockerfile" },
      generator_opts = {
        command = "dockerfmt",
        args = { "-i", "4" }, -- 缩进 4 空格
        to_stdin = true,
      },
      factory = h.formatter_factory,
    }

    -- Only insert new sources, do not replace the existing ones
    -- (If you wish to replace, use `opts.sources = {}` instead of the `list_insert_unique` function)
    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      -- Set a formatter
      -- null_ls.builtins.formatting.stylua,
      -- null_ls.builtins.formatting.prettier,
      nls.builtins.formatting.black,
      -- nls.builtins.formatting.isort,
      nls.builtins.formatting.isort.with { extra_args = { "--profile", "black" } },
      nls.builtins.formatting.shfmt.with {
        extra_args = { "-ci", "-i", "4" },
        filetypes = { "sh", "bash", "zsh" },
      },
      dockerfmt,
    })
  end,
}
