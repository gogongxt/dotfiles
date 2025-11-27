-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    ["sf"] = {
      "<cmd>lua require('spectre').open_file_search({select_word=false})<cr>",
      desc = "Search on current file",
    },
    ["sF"] = {
      "<cmd>lua require('spectre').open_visual({select_word=false})<cr>",
      desc = "Search on whole directory",
    },
    ["sw"] = {
      "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>",
      desc = "Search on current file",
    },
    ["sW"] = {
      "<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
      desc = "Search on whole directory",
    },
  },
  v = {
    ["sw"] = {
      '<esc><cmd>lua require("spectre").open({ search_text=require("plugins.user.my_funcs").get_text("v"), path=require("plugins.user.my_funcs").GetBufRelativePath()})<cr>',
      desc = "Search on current file",
    },
    ["sW"] = {
      '<esc><cmd>lua require("spectre").open({ search_text=require("plugins.user.my_funcs").get_text("v") })<cr>',
      desc = "Search on whole directory",
    },
  },
}

return {
  -- 增强搜索和替换
  "windwp/nvim-spectre",
  evnt = "VeryLazy",
  config = function()
    require("spectre").setup {
      is_block_ui_break = true,
      color_devicons = true,
      open_cmd = "vnew",
      live_update = true, -- auto execute search again when you write to any file in vim
      lnum_for_results = true, -- show line number for search/replace results
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
          map = "<c-q>",
          cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
          desc = "send all item to quickfix",
        },
        ["replace_cmd"] = {
          map = "C",
          cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
          desc = "input replace vim command",
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
          map = "<A-r>",
          cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
          desc = "update change when vim write file.",
        },
        ["toggle_ignore_case"] = {
          map = "<a-i>",
          cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
          desc = "toggle ignore case",
        },
        ["toggle_ignore_hidden"] = {
          map = "<a-h>",
          cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
          desc = "toggle search hidden",
        },
        ["resume_last_search"] = {
          map = "<c-o>",
          cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
          desc = "resume last search before close",
        },
        -- you can put your mapping here it only use normal mode
      },
    }
  end,
}
