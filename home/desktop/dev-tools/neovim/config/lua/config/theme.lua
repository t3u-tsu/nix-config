-- lua/config/theme.lua

local default_palette = {
  bg = "#0c0c0c",
  bg2 = "#1c1c1c",
  bg3 = "#262626",
  dim = "#5e5e5e",
  fg = "#ffffff",
  fg2 = "#a0a0a0",
  primary = "#ffc799",
  secondary = "#99ffe4",
  tertiary = "#fbadff",
  err = "#ff8080",
}

local v = vim.tbl_deep_extend("force", default_palette, vim.g.nix_palette or {})

local hi = function(g, o)
  vim.api.nvim_set_hl(0, g, o)
end

-- 基本エディタハイライト
hi("Normal", { fg = v.fg, bg = v.bg })
hi("NormalFloat", { fg = v.fg, bg = v.bg2 })
hi("Comment", { fg = v.fg2 })
hi("Identifier", { fg = v.primary })
hi("Function", { fg = v.secondary })
hi("Keyword", { fg = v.primary })
hi("Statement", { fg = v.primary })
hi("String", { fg = v.secondary })
hi("Type", { fg = v.primary })
hi("Constant", { fg = v.tertiary })
hi("PreProc", { fg = v.tertiary })
hi("Special", { fg = v.secondary })
hi("Operator", { fg = v.fg2 })
hi("Error", { fg = v.err })

-- UI 要素
hi("LineNr", { fg = v.fg2 })
hi("CursorLine", { bg = v.bg2 })
hi("CursorLineNr", { fg = v.primary, bg = v.bg2 })
hi("Visual", { bg = v.bg3 })
hi("StatusLine", { bg = v.bg2, fg = v.fg })
hi("StatusLineNC", { bg = v.bg, fg = v.fg2 })
hi("WinSeparator", { fg = v.dim })
hi("Pmenu", { bg = v.bg2, fg = v.fg })
hi("PmenuSel", { bg = v.bg3, fg = v.primary })
hi("TabLine", { bg = v.bg2, fg = v.fg2 })
hi("TabLineSel", { bg = v.bg, fg = v.primary })
hi("Search", { bg = v.primary, fg = v.bg })
hi("IncSearch", { bg = v.secondary, fg = v.bg })

-- 将来導入するプラグイン用ハイライト
hi("TelescopeNormal", { fg = v.fg, bg = v.bg })
hi("TelescopeBorder", { fg = v.dim, bg = v.bg })
hi("TelescopePromptTitle", { fg = v.bg, bg = v.primary })
hi("TelescopePreviewTitle", { fg = v.bg, bg = v.secondary })
hi("TelescopeResultsTitle", { fg = v.bg, bg = v.tertiary })
hi("TelescopeSelection", { fg = v.fg, bg = v.bg3 })
hi("TelescopeMatching", { fg = v.primary, bold = true })
hi("NvimTreeNormal", { fg = v.fg, bg = v.bg })
