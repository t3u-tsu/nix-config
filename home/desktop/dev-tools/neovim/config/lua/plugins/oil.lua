-- lua/plugins/oil.lua

return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false, -- ディレクトリを直接 nvim . で開いた際にも動くよう即時ロード
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
  },
}
