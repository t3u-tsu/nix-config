-- lua/plugins/lualine.lua

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = function()
    local p = vim.tbl_deep_extend("force", {
      bg = "#0c0c0c",
      bg2 = "#1c1c1c",
      fg = "#ffffff",
      fg2 = "#a0a0a0",
      primary = "#ffc799",
      secondary = "#99ffe4",
      err = "#ff8080",
    }, vim.g.nix_palette or {})

    local vesper_theme = {
      normal = {
        a = { fg = p.bg, bg = p.primary, gui = "bold" },
        b = { fg = p.fg, bg = p.bg2 },
        c = { fg = p.fg2, bg = p.bg },
      },
      insert = {
        a = { fg = p.bg, bg = p.secondary, gui = "bold" },
        b = { fg = p.fg, bg = p.bg2 },
        c = { fg = p.fg2, bg = p.bg },
      },
      visual = {
        a = { fg = p.bg, bg = p.primary, gui = "bold" },
        b = { fg = p.fg, bg = p.bg2 },
        c = { fg = p.fg2, bg = p.bg },
      },
      replace = {
        a = { fg = p.bg, bg = p.err, gui = "bold" },
        b = { fg = p.fg, bg = p.bg2 },
        c = { fg = p.fg2, bg = p.bg },
      },
      inactive = {
        a = { fg = p.fg2, bg = p.bg2 },
        b = { fg = p.fg2, bg = p.bg2 },
        c = { fg = p.fg2, bg = p.bg },
      },
    }

    return {
      options = {
        theme = vesper_theme,
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    }
  end,
}
