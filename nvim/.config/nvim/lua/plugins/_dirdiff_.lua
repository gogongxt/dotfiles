-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- use: :ZFDirDiff path1 path2
-- if has space use: :ZFDirDiff path\ 1 path\ 2
return {
  {
    "ZSaberLv0/ZFVimDirDiff",
    dependencies = {
      "ZSaberLv0/ZFVimJob",
      "ZSaberLv0/ZFVimIgnore",
    },
    cmd = "ZFDirDiff", -- Recommended: load on command
    config = function()
      -- ZFVimDirDiff uses global variables for configuration.
      -- It's recommended to set them before the plugin is loaded,
      -- which can be done in the `init` function.
    end,
    init = function()
      -- Example: Ignore common development directories and files
      -- This is a list of glob patterns.
      vim.g.ZFIgnore_userPat_ZFDirDiff = {
        ".git",
        ".svn",
        "node_modules",
        "dist",
        "build",
        "*.pyc",
        "*.swp",
        "*.swo",
        "__pycache__",
      }

      vim.g.ZFDirDiffKeymap_update = { "i" }
      vim.g.ZFDirDiffKeymap_open = { "<cr>", "o", "l", "h" }
      vim.g.ZFDirDiffKeymap_foldClose = { "h" }

      -- Show hidden files (default is 1)
      vim.g.ZFDirDiff_showHidden = 1

      -- Compare by file content (default is 'content')
      -- Other options: 'size', 'timestamp'
      vim.g.ZFDirDiff_compareOption = "content"
    end,
  },
}
