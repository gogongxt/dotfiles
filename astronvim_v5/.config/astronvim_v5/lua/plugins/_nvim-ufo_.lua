-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
    },
    event = "BufReadPost",
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
      fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (" ⋯ %d "):format(endLnum - lnum) -- ⋯ 󰘖
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
              suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end

        -- 定义颜色配置函数
        local setup_custom_colors = function()
          -- 使用 vim.api.nvim_set_hl 直接设置颜色
          vim.api.nvim_set_hl(0, "CustomFoldTextColor", { fg = "#000000", bg = "#8caaef" })
        end
        -- 在初始化时设置颜色
        setup_custom_colors()
        -- 监听 ColorScheme 事件，确保切换主题时重新设置颜色
        vim.api.nvim_create_autocmd("ColorScheme", {
          pattern = "*",
          callback = setup_custom_colors,
        })

        table.insert(newVirtText, { suffix, "CustomFoldTextColor" })
        return newVirtText
      end,
    },
    init = function()
      vim.keymap.set("n", "zR", function() require("ufo").openAllFolds() end)
      vim.keymap.set("n", "zM", function() require("ufo").closeAllFolds() end)
    end,
  },
}
