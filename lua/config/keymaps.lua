-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local function copy_current_line_to_system_clipboard()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  vim.fn.setreg("+", line)
end

-- Editing without yank
vim.keymap.set({ "n", "v" }, "d", [["_d]], { desc = "Delete without yank" })
vim.keymap.set({ "n", "v" }, "D", [["_D]], { desc = "Delete until end without yank" })
vim.keymap.set({ "n", "v" }, "c", [["_c]], { desc = "Change without yank" })
vim.keymap.set({ "n", "v" }, "C", [["_C]], { desc = "Change until end without yank" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete char without yank" })
vim.keymap.set({ "n", "v" }, "X", [["_X]], { desc = "Delete char backward without yank" })

-- Buffer navigation
vim.keymap.set({ "n", "v" }, "E", "<cmd>bnext<CR>", { desc = "Next Buffer" })
vim.keymap.set({ "n", "v" }, "R", "<cmd>bprevious<CR>", { desc = "Prev Buffer" })

-- Line movement and escape
vim.keymap.set({ "n", "v", "o" }, "H", "^", { desc = "Go line start" })
vim.keymap.set({ "n", "v", "o" }, "L", "$", { desc = "Go line end" })
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

-- macOS clipboard integration
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy selection to system clipboard" })
vim.keymap.set("n", "<D-c>", '"+yy', { desc = "Copy line to system clipboard" })
vim.keymap.set("i", "<D-c>", copy_current_line_to_system_clipboard, { desc = "Copy current line to system clipboard" })
