if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- vim.api.nvim_create_autocmd({ "VimEnter" }, {
--   callback = function() vim.api.nvim_command "LLMAppHandler Completion" end,
-- })

return {
  "Kurama622/llm.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "Kurama622/nui.nvim", "Kurama622/windsurf.nvim" },
  cmd = { "LLMSessionToggle", "LLMSelectedTextHandler", "LLMAppHandler" },
  lazy = false,
  config = function()
    local tools = require "llm.tools" -- for app tools
    require("llm").setup {
      url = "http://$TODO/v1/completions",
      -- model = "qwen2.5-coder:1.5b",
      model = "qwen3:30b",
      api_type = "ollama",
      app_handler = {
        -- ref: https://github.com/Kurama622/llm.nvim/issues/49
        Completion = {
          handler = tools.completion_handler,
          opts = {
            -------------------------------------------------
            ---                   ollama
            -------------------------------------------------
            url = "http://$TODO/v1/completions",
            -- WARNING: not support qwen3-coder:30b
            -- unknown error: registry.ollama.ai/library/qwen3-coder:30b does not support insert
            -- model = "qwen3-coder:30b",
            model = "qwen2.5-coder:1.5b",
            -- model = "qwen3:30b",
            api_type = "ollama",
            ------------------- end ollama ------------------

            n_completions = 2,
            context_window = 512,
            max_tokens = 256,

            -- A mapping of filetype to true or false, to enable completion.
            filetypes = { sh = false },

            -- -- Whether to enable completion of not for filetypes not specifically listed above.
            default_filetype_enabled = true,

            auto_trigger = true,

            -- just trigger by { "@", ".", "(", "[", ":", " " } for `style = "nvim-cmp"`
            only_trigger_by_keywords = true,

            style = "virtual_text", -- nvim-cmp or blink.cmp

            timeout = 100, -- max request time

            -- only send the request every x milliseconds, use 0 to disable throttle.
            -- throttle = 1000,
            throttle = 1000,
            -- debounce the request in x milliseconds, set to 0 to disable debounce
            -- debounce = 400,
            debounce = 400,

            --------------------------------
            ---   just for virtual_text
            --------------------------------
            keymap = {
              virtual_text = {
                accept = {
                  mode = "i",
                  keys = "<A-a>",
                },
                next = {
                  mode = "i",
                  keys = "<A-n>",
                },
                prev = {
                  mode = "i",
                  keys = "<A-p>",
                },
                toggle = {
                  mode = "n",
                  keys = "<leader>cp",
                },
              },
            },
          },
        },
        WordTranslate = {
          handler = tools.flexi_handler,
          --           prompt = [[You are a translation expert. Your task is to translate all the text provided by the user into Chinese.
          --
          -- NOTE:
          -- - All the text input by the user is part of the content to be translated, and you should ONLY FOCUS ON TRANSLATING THE TEXT without performing any other tasks.
          -- - RETURN ONLY THE TRANSLATED RESULT.]],
          prompt = "Translate the following text to Chinese, please only return the translation",

          opts = {
            url = "http://$TODO/api/chat",
            -- model = "qwen2.5-coder:1.5b",
            model = "qwen3:30b",
            api_type = "ollama",
            exit_on_move = true,
            enter_flexible_window = false,
          },
        },
      },
    }
  end,
  keys = {
    { "<leader>tp", mode = "x", "<cmd>LLMAppHandler WordTranslate<cr>" },
  },
}
