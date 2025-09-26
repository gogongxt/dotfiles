-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- maybe need a larger number if the machine's performance is low
local debounce_delay = os.getenv "NVIM_AUTOSAVE_DEBOUNCE_DELAY" or 135

-- auto save
return {
  -- {
  --   "pocco81/auto-save.nvim",
  --   config = function() require("auto-save").setup() end,
  -- },
  {
    "okuuva/auto-save.nvim",
    -- version = "^1.0.0", -- see https://devhints.io/semver, alternatively use '*' to use the latest tagged release
    cmd = "ASToggle", -- optional for lazy loading on command
    event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
    opts = {
      -- your config goes here
      -- or just leave it empty :)
      debounce_delay = debounce_delay, -- delay after which a pending save is executed
      -- solve autosave bug: https://github.com/coder/claudecode.nvim#auto-save-plugin-issues
      condition = function(buf)
        -- Exclude claudecode diff buffers by buffer name patterns
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname:match "%(proposed%)" or bufname:match "%(NEW FILE %- proposed%)" or bufname:match "%(New%)" then
          return false
        end

        -- Exclude by buffer variables (claudecode sets these)
        if
          vim.b[buf].claudecode_diff_tab_name
          or vim.b[buf].claudecode_diff_new_win
          or vim.b[buf].claudecode_diff_target_win
        then
          return false
        end

        -- Exclude by buffer type (claudecode diff buffers use "acwrite")
        local buftype = vim.fn.getbufvar(buf, "&buftype")
        if buftype == "acwrite" then return false end

        return true -- Safe to auto-save
      end,
    },
  },
  -- {
  --   "djoshea/vim-autoread",
  -- },
}
