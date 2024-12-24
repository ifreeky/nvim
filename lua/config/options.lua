-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt
opt.clipboard = ""
opt.termguicolors = true

-- 手动设置 Cursor 颜色
vim.api.nvim_set_hl(0, "Cursor", { fg = "#ffffff", bg = "#ff0000" })
vim.api.nvim_set_hl(0, "lCursor", { fg = "#000000", bg = "#00ff00" })

-- 启用终端的 GUI 光标
vim.opt.guicursor = "n-v-c:block-Cursor,i-ci-ve:ver25-Cursor,r-cr:hor20-Cursor"
