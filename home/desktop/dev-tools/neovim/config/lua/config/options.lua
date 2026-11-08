-- lua/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- 行番号 (ハイブリッド表示: 現在行は絶対番号，他は相対番号)
opt.number = true
opt.relativenumber = true

-- インデント (スペース2文字)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- 検索
opt.ignorecase = true
opt.smartcase = true

-- UI と視界
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true

-- ウィンドウ分割
opt.splitright = true
opt.splitbelow = true

-- システム連携と永続化
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
