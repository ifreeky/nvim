-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local english_input_source = "com.apple.keylayout.ABC"
local restore_input_source

local function has_macism()
  return vim.fn.executable("macism") == 1
end

local function run_macism(args)
  local result = vim.system(vim.list_extend({ "macism" }, args or {}), { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout or "")
end

local function current_input_source()
  local source = run_macism({})
  if source == nil or source == "" then
    return nil
  end
  return source
end

local function switch_input_source(target)
  if target == nil or target == "" then
    return false
  end
  return run_macism({ target }) ~= nil
end

if has_macism() then
  local group = vim.api.nvim_create_augroup("ifreeky_input_method_switch", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      local source = current_input_source()
      if source ~= nil and source ~= "" and source ~= english_input_source then
        restore_input_source = source
      end
      switch_input_source(english_input_source)
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      if restore_input_source ~= nil and restore_input_source ~= "" then
        switch_input_source(restore_input_source)
      end
    end,
  })
end

-- ── Special window management (Esc to leave, Shift-Esc to close) ────────────

local function is_editor_window(win)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == ""
end

local function current_tab_editor_windows()
  local wins = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_window(win) then
      wins[#wins + 1] = win
    end
  end

  return wins
end

local function find_editor_window(opts)
  opts = opts or {}
  local exclude = opts.exclude
  local last = vim.t.last_editor_win

  if last and last ~= exclude and is_editor_window(last) then
    return last
  end

  for _, win in ipairs(current_tab_editor_windows()) do
    if win ~= exclude then
      return win
    end
  end
end

local function focus_editor_window()
  local target = find_editor_window({ exclude = vim.api.nvim_get_current_win() })
  if target then
    vim.api.nvim_set_current_win(target)
    return true
  end

  return false
end

local function close_special_window()
  local current = vim.api.nvim_get_current_win()
  local target = find_editor_window({ exclude = current })

  pcall(vim.api.nvim_win_close, current, true)

  if target and vim.api.nvim_win_is_valid(target) then
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(target) then
        vim.api.nvim_set_current_win(target)
      end
    end)
  end
end

local function leave_special_window()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == "t" then
    vim.api.nvim_feedkeys(vim.keycode("<C-\\><C-n>"), "n", false)
    vim.schedule(focus_editor_window)
    return
  end

  if mode:sub(1, 1) == "i" then
    vim.cmd.stopinsert()
    vim.schedule(focus_editor_window)
    return
  end

  focus_editor_window()
end

local function close_and_leave_special_window()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == "t" then
    vim.api.nvim_feedkeys(vim.keycode("<C-\\><C-n>"), "n", false)
    vim.schedule(close_special_window)
    return
  end

  if mode:sub(1, 1) == "i" then
    vim.cmd.stopinsert()
    vim.schedule(close_special_window)
    return
  end

  close_special_window()
end

local special_window_group = vim.api.nvim_create_augroup("ifreeky_special_window_shortcuts", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
  group = special_window_group,
  callback = function(args)
    local buf = args.buf
    if vim.bo[buf].buftype == "" then
      vim.t.last_editor_win = vim.api.nvim_get_current_win()
      return
    end

    local opts = { buffer = buf, silent = true, nowait = true }
    vim.keymap.set({ "n", "i", "t" }, "<Esc>", leave_special_window, opts)
    vim.keymap.set({ "n", "i", "t" }, "<S-Esc>", close_and_leave_special_window, opts)
  end,
})
