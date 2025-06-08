-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    opts.window = {
      width = 30,
      mappings = {
        ["<S-CR>"] = "system_open",
        ["<Space>"] = "copy_to_clipboard", -- disable space until we figure out which-key disabling
        -- ["<S-h>"] = "prev_source",
        -- ["<S-l>"] = "next_source",
        P = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
        -- P = false,
        p = "paste_from_clipboard",
        o = "system_open",
        y = "copy_selector",
        h = "parent_or_close",
        l = "child_or_open",
      },
      fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
        ["<C-J>"] = "move_cursor_down",
        ["<C-K>"] = "move_cursor_up",
      },
    }
    opts.filesystem = {
      use_libuv_file_watcher = true, -- use the OS level file watchers to detect changes
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      hijack_netrw_behavior = "open_current",
      filtered_items = {
        -- set always show hidden file
        visible = true,
      },
    }
    return opts
  end,
}
