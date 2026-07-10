local make_repeatable = require("plugins.user.my_funcs.repeat").make_repeatable

local opts = { noremap = true, silent = true }
local keymap = vim.keymap
keymap.set("i", "jk", "<Esc>", opts)
keymap.set("n", "<leader>\\", "<C-w>v", opts)
keymap.set("n", "<leader><BS>", "<C-w>v", opts)
keymap.set("n", "<leader>-", "<C-w>s", opts)
-- keymap.set("n", "<C-s>", "<cmd>w<cr>", opts)
-- keymap.set("n", "<S-h>", "<cmd>bpre<cr>", opts)
-- keymap.set("n", "<S-l>", "<cmd>bnext<cr>", opts)
-- keymap.set("n", "<S-h>", "<cmd>lua require('astrocore.buffer').nav(vim.v.count1)<cr>", opts)
-- keymap.set("n", "<S-l>", "<cmd>lua require('astrocore.buffer').nav(-vim.v.count1)<cr>", opts)
--

-- Visual --
-- Stay in indent mode
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)
-- Move text up and down
keymap.set("v", "<A-j>", ":m .+1<CR>==", opts)
keymap.set("v", "<A-k>", ":m .-2<CR>==", opts)
-- Visual Block --
-- Move text up and down
keymap.set("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap.set("x", "K", ":move '<-2<CR>gv-gv", opts)
keymap.set("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap.set("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- nvim tab operation
for i = 1, 9 do
  vim.keymap.set("n", "<Leader>" .. i, function()
    local tab_count = vim.fn.tabpagenr "$"
    if i <= tab_count then
      -- Tab exists, just switch to it
      vim.cmd(i .. "tabnext")
    elseif i == tab_count + 1 then
      -- Next sequential tab, create it
      vim.cmd "tabnew"
    else
      -- Trying to jump to non-sequential tab
      vim.notify("Can't jump to tab " .. i .. ". Create tab " .. (tab_count + 1) .. " first.", vim.log.levels.WARN)
    end
  end, { desc = i <= 1 and "Go to tab " .. i or "Go to or create tab " .. i })
end

local function move_buf_to_tab(n)
  local cur_buf = vim.api.nvim_get_current_buf()
  local tabs = vim.api.nvim_list_tabpages()
  local tab_count = #tabs
  -- 第一步：在当前窗口用一个空 buffer 替换掉要移动的 buffer
  -- 防止 hide/close 导致 E444 “关闭最后窗口”
  vim.cmd "enew" -- 当前 window 切到一个新的空 buffer (scratch buffer)
  -- 第二步：如果目标 tab 存在，直接切过去
  if n <= tab_count then
    vim.api.nvim_set_current_tabpage(tabs[n])
    vim.cmd("buffer " .. cur_buf)
    return
  end
  -- 第三步：目标 tab 不存在，创建一个新的 tab 再移动过去
  vim.cmd "tabnew"
  local new_tabs = vim.api.nvim_list_tabpages()
  local new_tab = new_tabs[#new_tabs]
  vim.api.nvim_set_current_tabpage(new_tab)
  vim.cmd("buffer " .. cur_buf)
end
for i = 1, 9 do
  vim.keymap.set(
    "n",
    "<leader>bm" .. i,
    function() move_buf_to_tab(i) end,
    { desc = "Move current buffer to tab " .. i }
  )
end

-- toggle snacks image show
-- Ref: https://github.com/folke/snacks.nvim/issues/1739#issuecomment-3413850508
--
-- NOTE: The on_lines callback from vim.api.nvim_buf_attach is NOT an autocmd,
-- so clearing augroups doesn't stop it. We monkey-patch Snacks.image.placement.new
-- to respect snacks_disabled flag.
--
-- Store original placement.new function
local original_placement_new = nil
local dummy_id = 0
-- Create a dummy placement object that satisfies inline.lua's expectations
local function create_dummy_placement(src)
  dummy_id = dummy_id + 1
  return {
    id = dummy_id,
    eids = {},
    img = { src = src },
    opts = {},
    closed = true,
    close = function(self) end,
    update = function(self) end,
    show = function(self) end,
    hide = function(self) end,
  }
end
local disable_snacks_image = function()
  -- Some group names depend on image ID so we find them based on their events
  local events = {
    "BufWinEnter",
    "WinEnter",
    "BufWinLeave",
    "BufEnter",
    "WinClosed",
    "WinNew",
    "WinResized",
    "BufWritePost",
    "WinScrolled",
    "ModeChanged",
    "CursorMoved",
    "BufWipeout",
    "BufDelete",
    "BufWriteCmd",
    "FileType",
    "BufReadCmd",
  }
  local all_autocmds = vim.api.nvim_get_autocmds { event = events }
  local image_autocmds = {}
  local group_set = {}
  for _, autocmd in ipairs(all_autocmds) do
    if autocmd.group_name ~= nil and string.find(autocmd.group_name, "snacks.image", 1, true) then
      image_autocmds[#image_autocmds + 1] = autocmd
      group_set[autocmd.group_name] = true
    end
  end
  -- Save autocmds and augroups for when it is time to re-enable
  _G.image_autocmds = image_autocmds
  _G.image_augroups = group_set
  -- Clean buffer and clear augroups
  Snacks.image.placement.clean()
  for group, _ in pairs(group_set) do
    vim.api.nvim_create_augroup(group, { clear = true })
  end
  -- Monkey-patch placement.new to block new image creation
  -- Always save the current function in case it was restored by enable
  original_placement_new = Snacks.image.placement.new
  Snacks.image.placement.new = function(buf, src, opts)
    if _G.snacks_disabled then return create_dummy_placement(src) end
    return original_placement_new(buf, src, opts)
  end
  -- Set config.enabled so doc.attach guard blocks new attachments
  Snacks.image.config.enabled = false
  -- For toggle
  _G.snacks_disabled = true
end
-- Re-enable snacks.image after it was disabled
-- The function re-creates all autocmds and then re-attaches all buffers that were attached
local enable_snacks_image = function()
  -- Restore original placement.new
  if original_placement_new then Snacks.image.placement.new = original_placement_new end
  -- Restore config.enabled so doc.attach works again
  Snacks.image.config.enabled = true
  -- Re-create the groups
  for group, _ in pairs(image_augroups) do
    vim.api.nvim_create_augroup(group, { clear = true })
  end
  -- Re-create autocmds. Some keys need to be cleared or modified
  -- so that format from get_autocmds works with create_autocmd
  for _, autocmd in ipairs(image_autocmds) do
    -- Copy to avoid mutating stored autocmds (needed for toggle re-enable)
    local ac = {}
    for k, v in pairs(autocmd) do
      ac[k] = v
    end
    ac.group = ac.group_name
    if ac.command == "" then ac.command = nil end
    ac.group_name = nil
    local event = ac.event
    ac.event = nil
    ac.id = nil
    if ac.buflocal then
      ac.pattern = nil
      ac.buffer = ac.buf
    end
    ac.buf = nil
    ac.buflocal = nil
    if event then vim.api.nvim_create_autocmd(event, ac) end
  end
  -- Loop over buffers and enable those with compatible filetype
  local bufs = vim.api.nvim_list_bufs()
  local langs = Snacks.image.langs()
  for _, buf in ipairs(bufs) do
    local ft = vim.bo[buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if vim.tbl_contains(langs, lang) then
      -- Make sure the buffer is detached otherwise attach does nothing
      vim.b[buf].snacks_image_attached = false
      Snacks.image.doc.attach(buf)
    end
  end
  _G.snacks_disabled = false
end
local toggle_snacks_image = function()
  if snacks_disabled == nil then _G.snacks_disabled = false end
  if snacks_disabled then
    enable_snacks_image()
  else
    disable_snacks_image()
  end
end

local function toggle_render()
  if vim.bo.filetype == "markdown" then
    vim.cmd "RenderMarkdown toggle"
    toggle_snacks_image()
  elseif vim.bo.filetype == "csv" then
    vim.cmd "CsvViewToggle display_mode=border"
  else
    vim.cmd "Neogen"
  end
end

local mappings = require "mappings"
mappings.set_mappings {
  n = {
    -- delete comments
    ["<leader>Q"] = {
      ":tabclose<cr>",
      desc = "Close Tab",
      noremap = true,
      silent = true,
    },
    ["<leader>ld"] = {
      "<cmd>lua require('plugins.user.my_funcs.delete_comments').delete_comments()<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
    ["<leader>ln"] = {
      "<cmd>lua require('plugins.user.my_funcs.insert_blank_lines').insert_blank_lines()<cr>",
      desc = "Insert Blank Lines",
      noremap = true,
      silent = true,
    },
    ["<C-/>"] = {
      toggle_render,
      desc = "Toggle Render",
    },
    ["<C-_>"] = {
      toggle_render,
      desc = "Toggle Render",
    },
    -- treesitter class navigation
    ["]c"] = {
      function() require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects") end,
      desc = "Next class start",
    },
    ["]C"] = {
      function() require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects") end,
      desc = "Next class end",
    },
    ["[c"] = {
      function() require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects") end,
      desc = "Prev class start",
    },
    ["[C"] = {
      function() require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects") end,
      desc = "Prev class end",
    },
    -- treesitter class swap
    [">C"] = {
      function() require("nvim-treesitter-textobjects.swap").swap_next("@class.outer", "textobjects") end,
      desc = "Swap next class",
    },
    ["<C"] = {
      function() require("nvim-treesitter-textobjects.swap").swap_previous("@class.outer", "textobjects") end,
      desc = "Swap prev class",
    },
    ["gn"] = {
      make_repeatable(function() Snacks.words.jump(1, true) end),
      expr = true,
      desc = "Next Reference",
    },
    ["gp"] = {
      make_repeatable(function() Snacks.words.jump(-1, true) end),
      expr = true,
      desc = "Prev Reference",
    },

    -- fold commands
    ["za"] = {
      make_repeatable(function()
        local ok, err = pcall(vim.cmd, "normal! za")
        if not ok then vim.notify("No fold found", vim.log.levels.WARN) end
      end),
      expr = true,
      desc = "Toggle fold",
    },
    ["zc"] = {
      make_repeatable(function()
        local ok, err = pcall(vim.cmd, "normal! zc")
        if not ok then vim.notify("No fold found", vim.log.levels.WARN) end
      end),
      expr = true,
      desc = "Close fold",
    },
    ["zo"] = {
      make_repeatable(function()
        local ok, err = pcall(vim.cmd, "normal! zo")
        if not ok then vim.notify("No fold found", vim.log.levels.WARN) end
      end),
      expr = true,
      desc = "Open fold",
    },
    ["zA"] = {
      make_repeatable(function()
        local ok, err = pcall(vim.cmd, "normal! zA")
        if not ok then vim.notify("No fold found", vim.log.levels.WARN) end
      end),
      expr = true,
      desc = "Toggle fold recursively",
    },
    ["zC"] = {
      make_repeatable(function()
        local ok, err = pcall(vim.cmd, "normal! zC")
        if not ok then vim.notify("No fold found", vim.log.levels.WARN) end
      end),
      expr = true,
      desc = "Close fold recursively",
    },
    ["zO"] = {
      make_repeatable(function()
        local ok, err = pcall(vim.cmd, "normal! zO")
        if not ok then vim.notify("No fold found", vim.log.levels.WARN) end
      end),
      expr = true,
      desc = "Open fold recursively",
    },

    ["<c-g>"] = {
      (function()
        local last_press = 0
        return function()
          local now = vim.uv.now()
          local full_path = vim.fn.expand "%:p"
          if now - last_press < 500 then
            vim.fn.setreg("+", full_path)
            vim.notify("Path copied!", vim.log.levels.INFO)
          else
            local total_lines = vim.fn.line "$"
            local current_line = vim.fn.line "."
            local percent = math.modf((current_line / total_lines) * 100)
            vim.notify(string.format('"%s" %d lines --%d%%--', full_path, total_lines, percent), vim.log.levels.INFO)
          end
          last_press = now
        end
      end)(),
      noremap = true,
      silent = true,
    },

    -- debug dap
    ["<Leader>da"] = { function() require("dap-view").add_expr() end, desc = "Add expression" },
    ["<Leader>dE"] = false,
    ["<Leader>dR"] = { function() require("dap").run_last() end, desc = "Run last" },
    ["<Leader>dh"] = {
      function() require("dap.ui.widgets").hover(nil, { border = "rounded" }) end,
      desc = "Widgets hover",
    },
    ["<Leader>di"] = { function() require("dap").focus_frame() end, desc = "Focus frame" },
    ["<Leader>dj"] = {
      make_repeatable(function() require("dap").step_into() end),
      expr = true,
      desc = "Step into (F11)",
    },
    ["<Leader>dJ"] = {
      make_repeatable(function() require("dap").step_over() end),
      expr = true,
      desc = "Step over (F10)",
    },
    ["<Leader>do"] = {
      make_repeatable(function() require("dap").step_out() end),
      expr = true,
      desc = "Step out (S-F11)",
    },
    ["<Leader>dO"] = false,
    ["<Leader>dC"] = {
      make_repeatable(function() require("dap").run_to_cursor() end),
      expr = true,
      desc = "Run to cursor",
    },
    ["<a-p>"] = { function() require("dap.ui.widgets").preview() end, desc = "Widgets preview" },
    ["<Leader>dn"] = {
      make_repeatable(function()
        local breakpoints = require "dap.breakpoints"
        local bufnr = vim.api.nvim_get_current_buf()
        local cur_line = vim.api.nvim_win_get_cursor(0)[1]
        local bps = breakpoints.get(bufnr)[bufnr] or {}
        table.sort(bps, function(a, b) return a.line < b.line end)
        for _, bp in ipairs(bps) do
          if bp.line > cur_line then
            vim.api.nvim_win_set_cursor(0, { bp.line, 0 })
            return
          end
        end
        -- wrap around to first breakpoint
        if #bps > 0 then vim.api.nvim_win_set_cursor(0, { bps[1].line, 0 }) end
      end),
      expr = true,
      desc = "Next breakpoint",
    },
    ["<Leader>dp"] = {
      make_repeatable(function()
        local breakpoints = require "dap.breakpoints"
        local bufnr = vim.api.nvim_get_current_buf()
        local cur_line = vim.api.nvim_win_get_cursor(0)[1]
        local bps = breakpoints.get(bufnr)[bufnr] or {}
        table.sort(bps, function(a, b) return a.line > b.line end)
        for _, bp in ipairs(bps) do
          if bp.line < cur_line then
            vim.api.nvim_win_set_cursor(0, { bp.line, 0 })
            return
          end
        end
        -- wrap around to last breakpoint
        if #bps > 0 then vim.api.nvim_win_set_cursor(0, { bps[1].line, 0 }) end
      end),
      expr = true,
      desc = "Prev breakpoint",
    },
  },
  v = {
    -- delete comments
    ["<leader>ld"] = {
      "<cmd>lua require('plugins.user.my_funcs.delete_comments').delete_comments('v')<cr>",
      desc = "Delete Comments",
      noremap = true,
      silent = true,
    },
    ["<leader>ln"] = {
      "<cmd>lua require('plugins.user.my_funcs.insert_blank_lines').insert_blank_lines('v')<cr>",
      desc = "Insert Blank Lines",
      noremap = true,
      silent = true,
    },
  },
}
