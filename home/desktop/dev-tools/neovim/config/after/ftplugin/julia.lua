local opt = vim.opt_local

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.iskeyword:append("!")

local undo = "setlocal expandtab< shiftwidth< tabstop< softtabstop< iskeyword<"
vim.b.undo_ftplugin = vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | " .. undo) or undo
