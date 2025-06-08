-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {},
  v = {},
}

return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          ["<Leader>t"] = { "", desc = "󰊿 Translate", noremap = true, silent = true },
          -- remove toggleterm keymap
          ["<Leader>tf"] = false,
          ["<Leader>th"] = false,
          ["<Leader>tn"] = false,
          ["<Leader>tp"] = false,
          ["<Leader>tv"] = false,
          -- add translate keymap
          ["<Leader>tt"] = { "<cmd>Translate<cr>", desc = "translate words show", noremap = true, silent = true },
          ["<Leader>ts"] = {
            "<cmd>Translate --handle=split<cr>",
            desc = "translate words split",
            noremap = true,
            silent = true,
          },
          ["<Leader>tr"] = {
            "<cmd>Translate --handle=replace<cr>",
            desc = "translate words replace",
            noremap = true,
            silent = true,
          },
        },
        v = {
          ["<Leader>tt"] = {
            "<cmd>'<,'>Translate<cr>",
            desc = "translate words show",
            noremap = true,
            silent = true,
          },
          ["<Leader>ts"] = {
            "<cmd>'<,'>Translate --handle=split<cr>",
            desc = "translate words split",
            noremap = true,
            silent = true,
          },
          ["<Leader>tr"] = {
            "<cmd>'<,'>Translate --handle=replace<cr>",
            desc = "translate words replace",
            noremap = true,
            silent = true,
          },
        },
      },
    },
  },
  {
    "askfiy/smart-translate.nvim",
    cmd = { "Translate" },
    dependencies = {
      "askfiy/http.nvim", -- a wrapper implementation of the Python aiohttp library that uses CURL to send requests.
    },
    config = function()
      require("smart-translate").setup {
        default_config = {
          default = {
            cmds = {
              source = "auto",
              target = "zh-CN",
              handle = "float",
              engine = "google",
            },
            cache = true,
          },
          engine = {
            deepl = {
              -- Support SHELL variables, or fill in directly
              api_key = "$DEEPL_API_KEY",
              base_url = "https://api-free.deepl.com/v2/translate",
            },
          },
          hooks = {
            ---@param opts SmartTranslate.Config.Hooks.BeforeCallOpts
            ---@return string[]
            before_translate = function(opts) return opts.original end,
            ---@param opts SmartTranslate.Config.Hooks.AfterCallOpts
            ---@return string[]
            after_translate = function(opts) return opts.translation end,
          },
          -- Custom translator
          translator = {
            engine = {},
            handle = {},
          },
        },
      }
    end,
  },
}
