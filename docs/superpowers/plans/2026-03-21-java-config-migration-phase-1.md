# Java Config Migration Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the current `jdtls`-based Java configuration cleanly so the repository reaches a zero-Java-support baseline before introducing `nvim-java` in a later phase.

**Architecture:** Keep the implementation boundary narrow. Remove only the active Java plugin spec and its helper module, then verify that no active Neovim startup path still references them. Avoid unrelated refactors and avoid rewriting the already-dirty `lazy-lock.json` state.

**Tech Stack:** Neovim Lua config, LazyVim, lazy.nvim, ripgrep, git

---

## File Structure Map

- Delete: `lua/plugins/java.lua`
  Responsibility removed: custom Java plugin wiring for treesitter, Mason, Conform, and `jdtls`.
- Delete: `lua/config/helpers/java.lua`
  Responsibility removed: Java project root detection helper used by the old `jdtls` setup.
- Verify only: `lazy-lock.json`
  Responsibility: keep existing unrelated working-tree changes untouched during this phase.
- Reference: `docs/superpowers/specs/2026-03-21-java-config-migration-phase-1-design.md`
  Responsibility: phase 1 migration spec that this plan implements.

### Task 1: Confirm Removal Boundary

**Files:**
- Verify: `lua/plugins/java.lua`
- Verify: `lua/config/helpers/java.lua`
- Verify: `lazy-lock.json`

- [ ] **Step 1: Confirm the two Java files currently exist**

Run:

```bash
test -f /Users/ifreeky/.config/nvim/lua/plugins/java.lua && test -f /Users/ifreeky/.config/nvim/lua/config/helpers/java.lua
```

Expected: exit code `0`.

- [ ] **Step 2: Confirm active Java-related references are limited to the current Java path**

Run:

```bash
rg -n "config\\.helpers\\.java|jdtls|google-java-format" /Users/ifreeky/.config/nvim/lua
```

Expected: matches only in `lua/plugins/java.lua` and `lua/config/helpers/java.lua`.

- [ ] **Step 3: Confirm the lockfile is already dirty before edits**

Run:

```bash
git -C /Users/ifreeky/.config/nvim status --short
```

Expected: shows the pre-existing ` M lazy-lock.json` entry, with no Java-file deletions yet.

- [ ] **Step 4: Do not proceed if other active Lua files depend on the Java helper**

Decision rule:

```text
If Step 2 shows matches outside lua/plugins/java.lua and lua/config/helpers/java.lua, inspect those references first and update the plan execution accordingly before deleting files.
```

- [ ] **Step 5: Commit**

```bash
# No commit in this task. Proceed directly to Task 2 after the boundary check passes.
```

### Task 2: Remove the Old Java Path and Verify Startup

**Files:**
- Delete: `lua/plugins/java.lua`
- Delete: `lua/config/helpers/java.lua`
- Verify: `lazy-lock.json`

- [ ] **Step 1: Delete the Java plugin spec file**

Apply a patch that removes:

```text
/Users/ifreeky/.config/nvim/lua/plugins/java.lua
```

Expected: the file no longer exists after the patch.

- [ ] **Step 2: Delete the Java helper module**

Apply a patch that removes:

```text
/Users/ifreeky/.config/nvim/lua/config/helpers/java.lua
```

Expected: the file no longer exists after the patch.

- [ ] **Step 3: Re-scan for active Java configuration references**

Run:

```bash
rg -n "config\\.helpers\\.java|jdtls|google-java-format" /Users/ifreeky/.config/nvim/lua
```

Expected: no matches in `lua/`.

- [ ] **Step 4: Verify the deleted files are the only config changes in this phase**

Run:

```bash
git -C /Users/ifreeky/.config/nvim status --short
```

Expected: still shows the pre-existing `lazy-lock.json` modification plus deletions for:

```text
D lua/config/helpers/java.lua
D lua/plugins/java.lua
```

- [ ] **Step 5: Run the Neovim startup smoke test**

Run:

```bash
nvim --headless "+qa"
```

Expected: exit code `0` with no Lua/module/spec errors.

- [ ] **Step 6: Commit**

```bash
git -C /Users/ifreeky/.config/nvim add lua/plugins/java.lua lua/config/helpers/java.lua
git -C /Users/ifreeky/.config/nvim commit -m "refactor(nvim): remove legacy java config"
```

Expected: only perform this step if the user explicitly asks for a commit in this session.
