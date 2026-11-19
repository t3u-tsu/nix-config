-- lua/plugins/direnv.lua

return {
  "direnv/direnv.vim",
  lazy = false,
  cond = function()
    return vim.fn.executable("direnv") == 1
  end,
}
