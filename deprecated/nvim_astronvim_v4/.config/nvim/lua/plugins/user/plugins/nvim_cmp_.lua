-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {                    -- override nvim-cmp plugin
  "hrsh7th/nvim-cmp",
  keys = { ":", "/", "?" }, -- lazy load cmp on more keys along with insert mode
  dependencies = {
    "hrsh7th/cmp-cmdline",  -- add cmp-cmdline as dependency of cmp
  },
  -- override the options table that is used in the `require("cmp").setup()` call
  opts = function(_, opts)
    -- opts parameter is the default options table
    -- the function is lazy loaded so cmp is able to be required
    local cmp = require("cmp")

    -- modify the mapping part of the table
    -- opts.mapping["<C-x>"] = cmp.mapping.select_next_item()

    opts.completion = { completeopt = "menu,menuone,noinsert" }

    -- 修改tab为替换，<CR>默认就是直接插入了
    opts.mapping['<CR>'] = cmp.mapping.confirm({ select = true })
    -- 不用ctrl-enter,因为这个组合在tmux中识别不了
    -- opts.mapping["<C-Enter>"] = require("cmp").mapping(require('cmp').mapping.complete(), { "i", "c" })
    opts.mapping["<Down>"] = require("cmp").mapping({
      i = cmp.mapping.select_next_item(),
      c = cmp.mapping.select_next_item(),
    })
    opts.mapping["<Up>"] = require("cmp").mapping({
      i = cmp.mapping.select_prev_item(),
      c = cmp.mapping.select_prev_item(),
    })
    -- require('cmp').mapping.complete(), { "i", "c" }
    opts.mapping["<Tab>"] = require("cmp").mapping({
      i = require("cmp").mapping.confirm({ behavior = require("cmp").ConfirmBehavior.Replace, select = true }),
      c = function(fallback)
        if require("cmp").visible() then
          require("cmp").confirm({ behavior = require("cmp").ConfirmBehavior.Replace, select = true })
        else
          fallback()
        end
      end,
    })
    cmp.setup(opts)

    -- configure `cmp-cmdline` as described in their repo: https://github.com/hrsh7th/cmp-cmdline#setup
    cmp.setup.cmdline("/", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        {
          name = "cmdline",
          option = {
            ignore_cmds = { "Man", "!" },
          },
        },
      }),
    })
  end,
}
