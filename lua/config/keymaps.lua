-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- 删除不复制到寄存器
vim.keymap.set({ "n", "v" }, "d", [["_d]], { desc = "Delete without yank" })
vim.keymap.set({ "n", "v" }, "D", [["_D]], { desc = "Delete until end without yank" })
vim.keymap.set({ "n", "v" }, "c", [["_c]], { desc = "Change without yank" })
vim.keymap.set({ "n", "v" }, "C", [["_C]], { desc = "Change until end without yank" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete char without yank" })
vim.keymap.set({ "n", "v" }, "X", [["_X]], { desc = "Delete char backward without yank" })

vim.keymap.set({ "n", "v" }, "E", "<cmd>bnext<CR>", { desc = "Next Buffer" })
vim.keymap.set({ "n", "v" }, "R", "<cmd>bprevious<CR>", { desc = "Prev Buffer" })

-- H = 移动到行首
vim.keymap.set({ "n", "v", "o" }, "H", "^", { desc = "Go line start" })
-- L = 移动到行末
vim.keymap.set({ "n", "v", "o" }, "L", "$", { desc = "Go line end" })
-- 插入模式下，快速 jj 退出到普通模式
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })
