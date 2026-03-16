-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- proxy priority: PROXY > PROXY_DEFAULT > default
local proxy = os.getenv "PROXY" or os.getenv "PROXY_DEFAULT" or "http://127.0.0.1:7890"

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
          ["<Leader>tt"] = {
            "<cmd>Translate --target=zh-CN<cr>",
            desc = "translate words show",
            noremap = true,
            silent = true,
          },
          ["<Leader>tT"] = {
            "<cmd>Translate --target=en<cr>",
            desc = "translate words show",
            noremap = true,
            silent = true,
          },
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
            ":'<,'>Translate --target=zh-CN<cr>",
            desc = "translate words show",
            noremap = true,
            silent = true,
          },
          ["<Leader>tT"] = {
            ":'<,'>Translate --target=en<cr>",
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
    "gogongxt/smart-translate.nvim",
    cmd = { "Translate" },
    dependencies = {
      "askfiy/http.nvim", -- a wrapper implementation of the Python aiohttp library that uses CURL to send requests.
    },
    opts = {
      default = {
        cmds = {
          source = "auto",
          target = "zh-CN",
          handle = "float",
          engine = "baidu",
        },
        cache = true,
      },
      proxy = nil,
      engine = {
        deepl = {
          -- Support SHELL variables, or fill in directly
          api_key = "$DEEPL_API_KEY",
          base_url = "https://api-free.deepl.com/v2/translate",
        },
        baidu = {
          -- Support SHELL variables, or fill in directly
          app_id = "$NVIM_TRANSLATE_BAIDU_APP_ID",
          api_key = "$NVIM_TRANSLATE_BAIDU_API_KEY",
          base_url = "https://fanyi-api.baidu.com/ait/api/aiTextTranslate",
        },
      },
      hooks = {
        ---@param opts SmartTranslate.Config.Hooks.BeforeCallOpts
        ---@return string[]
        before_translate = function(opts)
          vim.notify("Begin Translate...", vim.log.levels.INFO, { title = "󰊿 Translate" })
          return opts.original
        end,
        ---@param opts SmartTranslate.Config.Hooks.AfterCallOpts
        ---@return string[]
        after_translate = function(opts)
          vim.notify("Translate Completely", vim.log.levels.INFO, { title = "󰊿 Translate" })
          return opts.translation
        end,
      },
      -- Custom translator
      translator = {
        engine = {},
        handle = {},
      },
    },
    config = function(_, opts) require("smart-translate").setup(opts) end,
  },
}
