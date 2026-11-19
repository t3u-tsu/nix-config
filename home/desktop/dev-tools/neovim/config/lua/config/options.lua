-- lua/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true

opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true

opt.splitright = true
opt.splitbelow = true

opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
