-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- 从环境变量读取配置
local api_key = os.getenv "NVIM_LLM_API_KEY" and "NVIM_LLM_API_KEY" or "TERM"
local end_point = os.getenv "NVIM_LLM_END_POINT" or "http://localhost:11434/v1/completions"
local model = os.getenv "NVIM_LLM_MODEL" or "qwen2.5-coder:1.5b"
local llm_enable = os.getenv "NVIM_LLM_ENABLE" or false

if not llm_enable or llm_enable == "false" or llm_enable == "0" then return {} end

return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "nvim_lua/plenary.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("minuet").setup {
        -- config options
        virtualtext = {
          auto_trigger_ft = { "*" },
          keymap = {
            accept_line = "<A-a>",
            accept = "<A-A>",
            -- accept n lines (prompts for number)
            -- e.g. "A-z 2 CR" will accept 2 lines
            accept_n_lines = "<A-z>",
            prev = "<A-p>",
            next = "<A-n>",
            dismiss = "<A-e>",
          },
          show_on_completion_menu = true,
        },
        provider = "openai_fim_compatible",
        n_completions = 3, -- recommend for local model for resource saving
        context_window = 512,
        provider_options = {
          openai_fim_compatible = {
            -- For Windows users, TERM may not be present in environment variables.
            -- Consider using APPDATA instead.
            api_key = api_key,
            name = "Ollama",
            end_point = end_point,
            model = model,
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
          },
        },
      }
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- Enable minuet for autocomplete
        default = { "lsp", "path", "buffer", "snippets", "minuet" },
        -- For manual completion only, remove 'minuet' from default
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            -- Should match minuet.config.request_timeout * 1000,
            -- since minuet.config.request_timeout is in seconds
            timeout_ms = 3000,
            score_offset = 50, -- Gives minuet higher priority among suggestions
          },
        },
      },
      -- Recommended to avoid unnecessary request
      completion = {
        trigger = { prefetch_on_insert = true },
        ghost_text = { enabled = false },
      },
    },
  },
}
