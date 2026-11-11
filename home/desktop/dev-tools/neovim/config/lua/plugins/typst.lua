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
    dependencies_bin = {
      tinymist = "tinymist",
    },
  },
}
