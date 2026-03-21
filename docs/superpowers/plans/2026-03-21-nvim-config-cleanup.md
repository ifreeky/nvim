# Neovim Config Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up the current LazyVim-based config so startup/load behavior is easier to read and the heaviest custom files have narrower responsibilities without changing the overall project layout.

**Architecture:** Keep `lua/config/*` and `lua/plugins/*` as the public structure. Move only low-level helper logic out of overloaded plugin files into small helper modules under `lua/config/helpers/*`, leaving the plugin entry files focused on registration, lifecycle hooks, and high-level policy. Because this is a configuration-only cleanup with no existing test harness, verification will use module existence checks and headless Neovim smoke tests instead of introducing a new test framework.

**Tech Stack:** Neovim Lua config, LazyVim, lazy.nvim, persistence.nvim, neo-tree, nvim-lspconfig, mason.nvim, conform.nvim

---

## File Structure Map

- Create: `lua/config/helpers/persistence.lua`
  Responsibility: house persistence-related utility functions that do not need to live inside the plugin spec file.
- Create: `lua/config/helpers/java.lua`
  Responsibility: house Java root detection and `jdtls` command resolution helpers.
- Modify: `lua/plugins/persistence.lua:1-103`
  Responsibility after cleanup: declare the persistence plugin and express session restore/autocmd policy at a high level.
- Modify: `lua/plugins/java.lua:1-132`
  Responsibility after cleanup: declare Java-related plugin wiring and reuse helper functions for root/cmd behavior.
- Modify: `lua/config/keymaps.lua:1-32`
  Responsibility after cleanup: remain a readable map of custom keybindings, grouped by editing/navigation/clipboard behavior.
- Modify: `README.md:1-4`
  Responsibility after cleanup: briefly describe this repository as a personal Neovim config rather than a stock LazyVim template.
- Delete: `lua/plugins/example.lua`
  Responsibility removed: unused template-only plugin example file.

### Task 1: Extract Persistence Helpers

**Files:**
- Create: `lua/config/helpers/persistence.lua`
- Modify: `lua/plugins/persistence.lua:1-103`

- [ ] **Step 1: Verify the new helper module does not exist yet**

Run:

```bash
nvim --headless "+lua require('config.helpers.persistence')" "+qa"
```

Expected: FAIL with a Lua `module 'config.helpers.persistence' not found` error.

- [ ] **Step 2: Write the helper module**

Add `lua/config/helpers/persistence.lua` with the extracted utility functions:

```lua
local M = {}

function M.is_dir(path)
  return path ~= nil and vim.fn.isdirectory(vim.fn.fnamemodify(path, ":p")) == 1
end

function M.open_explorer()
  vim.schedule(function()
    local ok, command = pcall(require, "neo-tree.command")
    if ok then
      command.execute({
        action = "show",
        source = "filesystem",
        position = "left",
        dir = vim.uv.cwd(),
      })
    end
  end)
end

function M.refresh_session_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        if vim.bo[buf].filetype == "" then
          local ft = vim.filetype.match({ buf = buf, filename = name })
          if ft and ft ~= "" then
            vim.bo[buf].filetype = ft
          end
        end

        if vim.bo[buf].filetype ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
          pcall(vim.treesitter.start, buf)
        end
      end
    end
  end
end

return M
```

- [ ] **Step 3: Thin the persistence plugin file**

Update `lua/plugins/persistence.lua` so it keeps the lifecycle policy but delegates low-level work:

```lua
local helpers = require("config.helpers.persistence")

return {
  {
    "folke/persistence.nvim",
    lazy = false,
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ifreeky_restore_buffer_features", { clear = true }),
        pattern = "PersistenceLoadPost",
        callback = function()
          vim.g.ifreeky_restore_buffers_pending = true
          vim.schedule(function()
            if package.loaded["nvim-treesitter"] then
              helpers.refresh_session_buffers()
              vim.g.ifreeky_restore_buffers_pending = false
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ifreeky_restore_buffer_features_after_verylazy", { clear = true }),
        pattern = "VeryLazy",
        callback = function()
          if vim.g.ifreeky_restore_buffers_pending then
            helpers.refresh_session_buffers()
            vim.g.ifreeky_restore_buffers_pending = false
          end
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("ifreeky_auto_restore_session", { clear = true }),
        callback = function()
          if vim.g.started_with_stdin then
            return
          end

          local argc = vim.fn.argc()
          local argv0 = argc > 0 and vim.fn.argv(0) or nil
          local entering_dir = argc == 1 and helpers.is_dir(argv0)
          if not (argc == 0 or entering_dir) then
            return
          end

          local persistence = require("persistence")
          local has_session = vim.fn.filereadable(persistence.current()) == 1
            or vim.fn.filereadable(persistence.current({ branch = false })) == 1

          if has_session then
            persistence.load()
            helpers.open_explorer()
            return
          end

          if entering_dir then
            helpers.open_explorer()
          end
        end,
      })
    end,
  },
}
```

- [ ] **Step 4: Run the persistence smoke checks**

Run:

```bash
nvim --headless "+lua local h=require('config.helpers.persistence'); assert(type(h.is_dir) == 'function'); assert(type(h.open_explorer) == 'function'); assert(type(h.refresh_session_buffers) == 'function')" "+qa"
```

Expected: PASS with no output.

Run:

```bash
nvim --headless "+qa"
```

Expected: PASS with no Lua/module/spec errors.

- [ ] **Step 5: Commit**

```bash
git add lua/config/helpers/persistence.lua lua/plugins/persistence.lua
git commit -m "refactor(nvim): split persistence helpers"
```

### Task 2: Extract Java Helpers

**Files:**
- Create: `lua/config/helpers/java.lua`
- Modify: `lua/plugins/java.lua:1-132`

- [ ] **Step 1: Verify the new Java helper module does not exist yet**

Run:

```bash
nvim --headless "+lua require('config.helpers.java')" "+qa"
```

Expected: FAIL with a Lua `module 'config.helpers.java' not found` error.

- [ ] **Step 2: Write the Java helper module**

Add `lua/config/helpers/java.lua`:

```lua
local M = {}

local function path_exists(path)
  return path ~= nil and (vim.uv or vim.loop).fs_stat(path) ~= nil
end

local function has_marker(dir, marker)
  return path_exists(vim.fs.joinpath(dir, marker))
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local dir = vim.fs.dirname(vim.fs.normalize(path))
  local maven_root
  local gradle_root
  local git_root

  while dir and dir ~= "" do
    if has_marker(dir, "pom.xml") or has_marker(dir, ".mvn") then
      maven_root = dir
    end

    if has_marker(dir, "settings.gradle")
      or has_marker(dir, "settings.gradle.kts")
      or has_marker(dir, "build.gradle")
      or has_marker(dir, "build.gradle.kts")
      or has_marker(dir, ".gradle") then
      gradle_root = dir
    end

    if has_marker(dir, ".git") then
      git_root = dir
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return maven_root or gradle_root or git_root
end

function M.root_dir(bufnr, on_dir)
  on_dir(M.find_root(vim.api.nvim_buf_get_name(bufnr)))
end

function M.jdtls_cmd()
  local cmd = vim.fn.exepath("jdtls")
  return { cmd ~= "" and cmd or "jdtls" }
end

return M
```

- [ ] **Step 3: Thin the Java plugin file**

Update `lua/plugins/java.lua` to import the helper module and keep only plugin wiring:

```lua
local java = require("config.helpers.java")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if not vim.tbl_contains(opts.ensure_installed, "java") then
        table.insert(opts.ensure_installed, "java")
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      for _, pkg in ipairs({ "google-java-format", "jdtls" }) do
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.java = { "google-java-format" }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      local server = opts.servers.jdtls == true and {} or opts.servers.jdtls or {}
      local existing_on_attach = server.on_attach

      server.cmd = java.jdtls_cmd()
      server.root_dir = java.root_dir
      server.single_file_support = false
      server.settings = vim.tbl_deep_extend("force", server.settings or {}, {
        java = {
          eclipse = { downloadSources = false },
          maven = { downloadSources = false },
          configuration = { updateBuildConfiguration = "interactive" },
          implementationsCodeLens = { enabled = false },
          inlayHints = { parameterNames = { enabled = "none" } },
          referencesCodeLens = { enabled = false },
        },
      })
      server.on_attach = function(client, bufnr)
        if existing_on_attach then
          existing_on_attach(client, bufnr)
        end
        vim.diagnostic.enable(false, { bufnr = bufnr })
      end

      opts.servers.jdtls = server
    end,
  },
}
```

- [ ] **Step 4: Run the Java smoke checks**

Run:

```bash
nvim --headless "+lua local j=require('config.helpers.java'); assert(type(j.find_root) == 'function'); assert(type(j.root_dir) == 'function'); assert(type(j.jdtls_cmd) == 'function')" "+qa"
```

Expected: PASS with no output.

Run:

```bash
nvim --headless "+qa"
```

Expected: PASS with no Lua/module/spec errors.

- [ ] **Step 5: Commit**

```bash
git add lua/config/helpers/java.lua lua/plugins/java.lua
git commit -m "refactor(nvim): split java helpers"
```

### Task 3: Clean Up Keymaps for Readability

**Files:**
- Modify: `lua/config/keymaps.lua:1-32`

- [ ] **Step 1: Capture the current keymap file shape**

Run:

```bash
sed -n '1,80p' lua/config/keymaps.lua
```

Expected: Shows a single file containing a local clipboard helper plus all keymap definitions.

- [ ] **Step 2: Rewrite the file into clearly grouped sections**

Reshape `lua/config/keymaps.lua` so it still defines the same mappings, but reads as grouped intent:

```lua
local function copy_current_line_to_system_clipboard()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  vim.fn.setreg("+", line)
end

-- Editing without polluting registers.
vim.keymap.set({ "n", "v" }, "d", [["_d]], { desc = "Delete without yank" })
vim.keymap.set({ "n", "v" }, "D", [["_D]], { desc = "Delete until end without yank" })
vim.keymap.set({ "n", "v" }, "c", [["_c]], { desc = "Change without yank" })
vim.keymap.set({ "n", "v" }, "C", [["_C]], { desc = "Change until end without yank" })
vim.keymap.set({ "n", "v" }, "x", [["_x]], { desc = "Delete char without yank" })
vim.keymap.set({ "n", "v" }, "X", [["_X]], { desc = "Delete char backward without yank" })

-- Buffer navigation.
vim.keymap.set({ "n", "v" }, "E", "<cmd>bnext<CR>", { desc = "Next Buffer" })
vim.keymap.set({ "n", "v" }, "R", "<cmd>bprevious<CR>", { desc = "Prev Buffer" })

-- Line movement and insert escape.
vim.keymap.set({ "n", "v", "o" }, "H", "^", { desc = "Go line start" })
vim.keymap.set({ "n", "v", "o" }, "L", "$", { desc = "Go line end" })
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true })

-- macOS clipboard integration.
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy selection to system clipboard" })
vim.keymap.set("n", "<D-c>", '"+yy', { desc = "Copy line to system clipboard" })
vim.keymap.set("i", "<D-c>", copy_current_line_to_system_clipboard, { desc = "Copy current line to system clipboard" })
```

- [ ] **Step 3: Verify the config still loads**

Run:

```bash
nvim --headless "+qa"
```

Expected: PASS with no Lua/module/spec errors.

- [ ] **Step 4: Commit**

```bash
git add lua/config/keymaps.lua
git commit -m "refactor(nvim): regroup custom keymaps"
```

### Task 4: Remove Template Residue

**Files:**
- Modify: `README.md:1-4`
- Delete: `lua/plugins/example.lua:1-80`

- [ ] **Step 1: Confirm the template residue is still present**

Run:

```bash
rg -n "starter template|if true then return \\{\\}" README.md lua/plugins/example.lua
```

Expected: MATCHES in both files.

- [ ] **Step 2: Replace the README with a repository-specific summary**

Rewrite `README.md` to something minimal and accurate, for example:

```markdown
# Neovim Config

Personal Neovim configuration built on top of LazyVim.

Most custom behavior lives in:

- `lua/config/*` for startup options, keymaps, and autocmd entry points
- `lua/plugins/*` for plugin specs and overrides
```

- [ ] **Step 3: Delete the unused example plugin spec**

Remove `lua/plugins/example.lua`.

- [ ] **Step 4: Verify the template residue is gone and startup still works**

Run:

```bash
rg -n "starter template|if true then return \\{\\}" README.md lua/plugins 2>/dev/null
```

Expected: no output.

Run:

```bash
nvim --headless "+qa"
```

Expected: PASS with no Lua/module/spec errors.

- [ ] **Step 5: Commit**

```bash
git add README.md lua/plugins/example.lua
git commit -m "docs(nvim): remove template residue"
```

### Task 5: Final Verification and Cleanup Summary

**Files:**
- Review: `lua/config/helpers/persistence.lua`
- Review: `lua/config/helpers/java.lua`
- Review: `lua/plugins/persistence.lua`
- Review: `lua/plugins/java.lua`
- Review: `lua/config/keymaps.lua`
- Review: `README.md`

- [ ] **Step 1: Run the full smoke check**

Run:

```bash
nvim --headless "+qa"
```

Expected: PASS with no startup errors.

- [ ] **Step 2: Review the final diff for scope control**

Run:

```bash
git diff --stat HEAD~4..HEAD
```

Expected: only the helper modules, targeted config files, README, and example-file deletion appear.

- [ ] **Step 3: Sanity-check responsibility boundaries**

Run:

```bash
sed -n '1,220p' lua/plugins/persistence.lua
sed -n '1,220p' lua/plugins/java.lua
```

Expected: each file reads as high-level plugin wiring rather than mixed wiring plus utility implementation.

- [ ] **Step 4: Final checkpoint commit if needed**

If any follow-up cleanup is required after verification:

```bash
git add lua/config/helpers/persistence.lua lua/config/helpers/java.lua lua/plugins/persistence.lua lua/plugins/java.lua lua/config/keymaps.lua README.md lua/plugins/example.lua
git commit -m "chore(nvim): finalize config cleanup"
```
