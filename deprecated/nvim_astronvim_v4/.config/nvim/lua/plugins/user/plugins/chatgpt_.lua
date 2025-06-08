-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local gp_enabled = require("my_sys").GetConfig("config_", "gp.gp_enabled", false)
local gp_proxy = require("my_sys").GetConfig("config_", "gp.gp_proxy", "")
local openai_api_key_file_path = require("my_sys").GetConfig("config_", "gp.gp_openai_key_file_path", "")
local openai_api_key_string = require("my_sys").GetConfig("config_", "gp.openai_api_key_string", "")
-- require("my_sys").DEBUG("openai_api_key_file_path", openai_api_key_file_path)
-- require("my_sys").DEBUG("openai_api_key_string", openai_api_key_string)

local openai_api_key = (openai_api_key_string ~= "") and openai_api_key_string
  or ((openai_api_key_file_path == "") and { "" } or { "cat", openai_api_key_file_path })
-- require("my_sys").DEBUG("openai_api_key", openai_api_key)

-- chatgpt openai插件
return {
  enabled = gp_enabled,

  "robitx/gp.nvim",
  config = function()
    require("gp").setup {
      openai_api_key = openai_api_key,
      -- openai_api_key = os.getenv("OPENAI_API_KEY"),
      curl_params = (gp_proxy == "") and {} or { "--proxy", gp_proxy },
    }
  end,
}
