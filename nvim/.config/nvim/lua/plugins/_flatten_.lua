-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "gogongxt/flatten.nvim",
    branch = "fix-swap-error",
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
          should_block = function(argv)
            for _, arg in ipairs(argv) do
              if arg:find "claude%-prompt.*%.md$" then return true end
            end
            return false
          end,
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
              if saved_terminal then
                if terminal_type == "float" then
                  -- Only reopen if it was a floating terminal
                  saved_terminal:open()
                elseif terminal_type == "split" then
                  -- For split terminals (like Claude Code), focus the terminal window
                  if saved_terminal:is_open() and saved_terminal.window then
                    vim.api.nvim_set_current_win(saved_terminal.window)
                    vim.cmd "startinsert"
                  end
                end
                saved_terminal = nil
              end
            end)
          end,
        },
      }
    end,
  },
}
