-- lua/plugins/typst.lua

return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = "1.*",
  cmd = { "TypstPreview", "TypstPreviewToggle", "TypstPreviewUpdate", "TypstPreviewStop" },
  keys = {
    { "<leader>tp", "<cmd>TypstPreviewToggle<cr>", desc = "Typst: Toggle preview", ft = "typst" },
  },
  opts = {
    open_cmd = vim.fn.executable("chromium") == 1 and "chromium --app=%s" or nil,
    dependencies_bin = setmetatable({}, {
      __index = function(_, key)
        if key == "tinymist" then
          local bin = vim.fn.exepath("tinymist")
          if bin ~= "" then
            return bin
          end
        end
        return nil
      end,
    }),
  },
}
