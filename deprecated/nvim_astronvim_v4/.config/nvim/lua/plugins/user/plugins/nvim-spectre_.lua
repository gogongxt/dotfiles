-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  -- 增强搜索和替换
  "windwp/nvim-spectre",
  event = "VeryLazy",
  config = function()
    require("spectre").setup {
      is_block_ui_break = true,
      color_devicons = true,
      open_cmd = "vnew",
      live_update = false, -- auto execute search again when you write to any file in vim
      -- if set follow then cannot use zo/zc to set fold
      -- line_sep_start = "┌-----------------------------------------",
      -- result_padding = "¦  ",
      -- line_sep = "└-----------------------------------------",
      highlight = { -- set with color group/ can use :highlight to see all color group
        ui = "String",
        search = "TodoBgTODO",
        replace = "TodoBgTEST",
      },
      mapping = {
        ["send_to_qf"] = {
          map = "F",
          cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
          desc = "send all item to quickfix",
        },
        ["replace_cmd"] = {
          map = "C",
          cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
          desc = "input replace vim command",
        },
        ["show_option_menu"] = {
          map = "M",
          cmd = "<cmd>lua require('spectre').show_options()<CR>",
          desc = "show option",
        },
        ["run_current_replace"] = {
          map = "r",
          cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
          desc = "replace current line",
        },
        ["run_replace"] = {
          map = "R",
          cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
          desc = "replace all",
        },
        ["change_view_mode"] = {
          map = "<A-v>",
          cmd = "<cmd>lua require('spectre').change_view()<CR>",
          desc = "change result view mode",
        },
        ["toggle_live_update"] = {
          map = "U",
          cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
          desc = "update change when vim write file.",
        },
        ["toggle_ignore_case"] = {
          map = "I",
          cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
          desc = "toggle ignore case",
        },
        ["toggle_ignore_hidden"] = {
          map = "H",
          cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
          desc = "toggle search hidden",
        },
        ["resume_last_search"] = {
          map = "L",
          cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
          desc = "resume last search before close",
        },
        -- you can put your mapping here it only use normal mode
      },
    }
  end,
}
