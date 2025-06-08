-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
  },
  {
    "gxt-kt/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("hlchunk").setup {
        chunk = {
          enable = true,
          use_treesitter = true,
          max_file_size = 1024 * 1024,
          exclude_filetypes = {
            aerial = true,
            dashboard = true,
          },
          chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            right_arrow = ">",
          },
          style = {
            { fg = "#CB8764" },
          },
          error_sign = true,
          duration = 150,
          delay = 50,
        },
        indent = {
          enable = true, --
          -- chars = { "│", "¦", "┆", "┊" },
          chars = { "▏" },
          -- chars = { " ", " ", " ", " " },
          use_treesitter = false,
          style = {
            -- { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") }
            { fg = "#51576e" },
          },
        },
        line_num = {
          enable = false,
          use_treesitter = true,
          style = "#806d9c",
        },
        blank = {
          enable = false,
          chars = {
            "․",
          },
          style = {
            vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID "Whitespace"), "fg", "gui"),
          },
        },
      }
    end,
  },
}
