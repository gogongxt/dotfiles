-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "willothy/flatten.nvim",
    config = true,
    lazy = false,
    priority = 1001,
    opts = function()
      ---@type Terminal?
      local saved_terminal
      local terminal_type = nil -- "float" or "split"

      return {
        window = {
          open = "alternate",
        },
        hooks = {
          pre_open = function()
            local term = require "toggleterm.terminal"
            local termid = term.get_focused_id()
            saved_terminal = term.get(termid)

            -- Determine terminal type
            local winid = vim.api.nvim_get_current_win()
            local config = vim.api.nvim_win_get_config(winid)
            terminal_type = config.relative ~= "" and "float" or "split"
          end,
          post_open = function(bufnr, winnr, ft, is_blocking)
            if is_blocking and saved_terminal then
              -- Hide the terminal while it's blocking
              saved_terminal:close()
            end

            -- Git commit handling
            if ft == "gitcommit" or ft == "gitrebase" then
              vim.api.nvim_create_autocmd("BufWritePost", {
                buffer = bufnr,
                once = true,
                callback = vim.schedule_wrap(function() vim.api.nvim_buf_delete(bufnr, {}) end),
              })
            end
          end,
          block_end = function()
            vim.schedule(function()
              if saved_terminal and terminal_type == "float" then
                -- Only reopen if it was a floating terminal
                saved_terminal:open()
                saved_terminal = nil
              end
            end)
          end,
        },
      }
    end,
  },
}
