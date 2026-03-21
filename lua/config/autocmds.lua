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
