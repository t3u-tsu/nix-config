-- lua/plugins/typst.lua

return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = "1.*",
  cmd = { "TypstPreview", "TypstPreviewToggle", "TypstPreviewUpdate", "TypstPreviewStop" },
  keys = {
    { "<leader>tp", "<cmd>TypstPreviewToggle<cr>", desc = "Typst: Toggle preview", ft = "typst" },
  },
  config = function()
    local preview = require("typst-preview")
    local preview_config = require("typst-preview.config")
    local servers = require("typst-preview.servers")
    local utils = require("typst-preview.utils")

    preview.setup({
      debug = true,
      open_cmd = vim.fn.executable("chromium") == 1 and "chromium --app=%s" or nil,
    })

    setmetatable(preview_config.opts.dependencies_bin, {
      __index = function(_, key)
        if key == "tinymist" then
          local bin = vim.fn.exepath("tinymist")
          if bin ~= "" then
            return bin
          end
        elseif key == "websocat" then
          local bin = vim.fn.exepath("websocat")
          if bin ~= "" then
            return bin
          end
        end
        return nil
      end,
    })

    -- Tinymist の jump_from_cursor 仕様（Text/MathText ノード直前のみ追従する制限）に対応するため、
    -- 行頭や記号位置でも行内の有効なテキスト文字へカーソル座標を補正して同期する
    servers.sync_with_cursor = function(self)
      if self.suppress then
        return
      end
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_idx = cursor[1] - 1
      local col = cursor[2]
      local line_str = (vim.api.nvim_buf_get_lines(0, line_idx, line_idx + 1, false)[1]) or ""

      -- 行内の最初の英数字またはマルチバイト文字（日本語）の位置を探す
      local text_pos = line_str:find("[%w\128-\255]")
      if text_pos then
        -- カーソルが行頭や記号位置にある場合、文字位置まで補正
        col = math.max(col, text_pos)
      else
        -- 空行の場合は直近のテキスト行を探す
        for offset = -1, -10, -1 do
          local target_idx = line_idx + offset
          if target_idx >= 0 then
            local prev_str = (vim.api.nvim_buf_get_lines(0, target_idx, target_idx + 1, false)[1]) or ""
            local prev_pos = prev_str:find("[%w\128-\255]")
            if prev_pos then
              line_idx = target_idx
              col = prev_pos
              break
            end
          end
        end
      end

      utils.debug("scroll to line: " .. line_idx .. ", character: " .. col)
      self.write(vim.json.encode({
        event = "panelScrollTo",
        filepath = utils.get_buf_path(0),
        line = line_idx,
        character = col,
      }) .. "\n")
    end
  end,
}
