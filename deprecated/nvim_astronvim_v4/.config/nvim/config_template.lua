-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- vim.opt.colorcolumn = "80" -- a line at 80 column postion -- 80 for google c++ style

vim.o.shellcmdflag = "-ci"

return {
  notify = {
    notify_enabled = false,
  },
  image = {
    image_enabled = false,
    backend = "ueberzug", -- kitty or ueberzug
  },
  gp = {
    gp_enabled = true,
    gp_proxy = "127.0.0.1:7890",
    -- 有string优先string，没有就cat file_path文件
    openai_api_key_string = "",
    gp_openai_key_file_path = "",
    -- gp_openai_key_file_path = vim.fn.stdpath "config" .. "/.openai_api_key",
  },
  leetcode = {
    leetcode_enabled = true,
    show_image = true,
    lang = "cpp",
    cn = {
      cn_enabled = true,
      translator = false,
      translate_problems = true,
    },
  },
  dap = {
    -- this plugin start is too slow(about 50ms)
    persistent_breakpoints_enabled = false,
  },
  heirline = {
    -- set false will use your own statuscol config
    statuscol_enabled = false,
  },
}
