-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.launch",
  command = "set filetype=xml",
})

-- set python tab is 4
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  command = "set tabstop=4  shiftwidth=4",
})

-- create colorcolum for cpp
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.cpp", "*.cc", "*.c", "*.h", "*.hpp", "*.cxx" },
  callback = function() vim.opt_local.colorcolumn = { 80 } end,
})

-- Sovle txt bug use kitty+tmux and show image
-- https://github.com/neovim/neovim/issues/21856
vim.api.nvim_create_autocmd({ "VimLeave" }, {
  callback = function()
    -- do nothing
    vim.fn.jobstart("", { detach = true })
  end,
})

return {}
