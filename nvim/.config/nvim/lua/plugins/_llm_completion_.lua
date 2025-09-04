-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

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
        },
        provider = "openai_fim_compatible",
        n_completions = 3, -- recommend for local model for resource saving
        context_window = 512,
        provider_options = {
          openai_fim_compatible = {
            -- For Windows users, TERM may not be present in environment variables.
            -- Consider using APPDATA instead.
            api_key = "API_KEY",
            name = "Ollama",
            end_point = "http://$TODO/v1/completions",
            -- model = "qwen2.5-coder:1.5b",
            -- model = "qwen3:30b",
            -- model = "qwen3-coder:30b",
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
          },
        },
      }
    end,
  },
}
