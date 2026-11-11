-- lua/plugins/treesitter.lua

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({})

    local parsers = {
      "lua",
      "vim",
      "vimdoc",
      "nix",
      "bash",
      "perl",
      "markdown",
      "markdown_inline",
      "typst",
    }
    pcall(require("nvim-treesitter").install, parsers)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitterHighlight", { clear = true }),
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
