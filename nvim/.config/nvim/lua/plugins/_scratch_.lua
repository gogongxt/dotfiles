-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "LintaoAmons/scratch.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  config = function()
    require("scratch").setup {
      scratch_file_dir = vim.fn.stdpath "cache" .. "/scratch.nvim", -- where your scratch files will be put
      window_cmd = "rightbelow vsplit", -- 'vsplit' | 'split' | 'edit' | 'tabedit' | 'rightbelow vsplit'
      use_telescope = false,
      -- fzf-lua is recommanded, since it will order the files by modification datetime desc. (require rg)
      file_picker = "snacks",
      filetypes = { "txt", "md", "log", "yaml", "lua", "js", "sh", "ts", "cpp", "cc", "c", "py" }, -- you can simply put filetype here
      filetype_details = { -- or, you can have more control here
        -- ["yaml"] = {},
        -- go = {
        --   requireDir = true, -- true if each scratch file requires a new directory
        --   filename = "main", -- the filename of the scratch file in the new directory
        --   content = { "package main", "", "func main() {", "  ", "}" },
        --   cursor = {
        --     location = { 4, 2 },
        --     insert_mode = true,
        --   },
        -- },
      },
      localKeys = {
        -- {
        --   filenameContains = { "sh" },
        --   LocalKeys = {
        --     {
        --       cmd = "<CMD>RunShellCurrentLine<CR>",
        --       key = "<C-r>",
        --       modes = { "n", "i", "v" },
        --     },
        --   },
        -- },
      },
      hooks = {
        -- {
        --   callback = function() vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello", "world" }) end,
        -- },
      },
    }
  end,
}
