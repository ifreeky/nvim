# Neovim Input Method Auto-Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add macOS input method auto-switching so leaving insert mode switches to English and re-entering insert mode restores the previously active non-English input method.

**Architecture:** Keep the feature local to `lua/config/autocmds.lua` as a small autocmd-driven behavior. Use `macism` directly for read/write operations, store one module-local restore target, and register the handlers in a dedicated augroup with reload-safe clearing. Because this is a config-only change with no test harness, verification will rely on command availability checks and headless Neovim smoke tests.

**Tech Stack:** Neovim Lua config, LazyVim, macOS, `macism`

---

## File Structure Map

- Modify: `lua/config/autocmds.lua`
  Responsibility: define the `macism`-backed input method helpers, the stored restore target, and the `InsertLeave` / `InsertEnter` autocmds in a dedicated augroup.
- Create: `docs/superpowers/plans/2026-03-21-input-method-switch.md`
  Responsibility: record the implementation steps for this feature.

### Task 1: Add `macism`-Backed Autocmd Logic

**Files:**
- Modify: `lua/config/autocmds.lua:1-200`

- [ ] **Step 1: Verify `macism` is available from the shell environment that launches Neovim**

Run:

```bash
command -v macism
```

Expected: PASS with an absolute path to the `macism` binary.

Run:

```bash
macism
```

Expected: PASS with the current input source ID on stdout.

- [ ] **Step 2: Add the helper state and shell wrappers to `lua/config/autocmds.lua`**

Add a small local implementation near the top of `lua/config/autocmds.lua`:

```lua
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
```

This keeps the shell contract explicit and gives the autocmd callbacks simple, testable helpers.

- [ ] **Step 3: Add a reload-safe augroup and the `InsertLeave` callback**

Append the dedicated augroup registration:

```lua
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
end
```

This step handles the "leave insert mode -> switch to English" half and records the restore target only when the prior source was not already English.

- [ ] **Step 4: Add the `InsertEnter` callback**

Extend the same augroup block with:

```lua
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      if restore_input_source ~= nil and restore_input_source ~= "" then
        switch_input_source(restore_input_source)
      end
    end,
  })
end
```

This restores the most recent non-English insert-mode input source without forcing a fixed Chinese layout.

- [ ] **Step 5: Run a targeted Lua smoke check**

Run:

```bash
nvim --headless "+lua dofile(vim.fn.stdpath('config') .. '/lua/config/autocmds.lua')" "+qa"
```

Expected: PASS with no Lua errors.

- [ ] **Step 6: Run the full headless startup check**

Run:

```bash
nvim --headless "+qa"
```

Expected: PASS with no startup/module/autocmd errors.

- [ ] **Step 7: Manually verify mode switching in a real Neovim session**

Manual check:

1. Launch `nvim` from a shell where `command -v macism` succeeds.
2. Switch macOS to a non-English input method.
3. Enter insert mode.
4. Leave insert mode and confirm the system input method changes to `ABC`.
5. Re-enter insert mode and confirm the prior non-English input method is restored.

Expected: normal mode uses English input, insert mode restores the previous non-English input method.

- [ ] **Step 8: Commit**

```bash
git add lua/config/autocmds.lua docs/superpowers/plans/2026-03-21-input-method-switch.md
git commit -m "feat(nvim): auto switch input method by mode"
```
