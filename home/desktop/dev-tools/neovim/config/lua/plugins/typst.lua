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
  end,
}
