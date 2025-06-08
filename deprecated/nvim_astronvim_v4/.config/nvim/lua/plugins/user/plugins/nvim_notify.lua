-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local notify_enabled = require("my_sys").GetConfig("config_", "notify.notify_enabled", false)

return {
  "rcarriga/nvim-notify",
  enabled = notify_enabled,
  event = "UIEnter",
}
