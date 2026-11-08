-- lua/plugins/telescope.lua

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<CMD>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<CMD>Telescope live_grep<CR>", desc = "Live grep" },
    { "<leader>fb", "<CMD>Telescope buffers<CR>", desc = "Find buffers" },
    { "<leader>fh", "<CMD>Telescope help_tags<CR>", desc = "Help tags" },
  },
  opts = {
    defaults = {
      prompt_prefix = "   ",
      selection_caret = "  ",
      layout_config = {
        horizontal = {
          preview_width = 0.55,
        },
      },
    },
  },
}
