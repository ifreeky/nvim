# Java Config Migration Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore Java support with the official minimal `nvim-java` setup so this Neovim config regains a clean baseline for Maven and Spring Boot development.

**Architecture:** Add a single Java plugin entrypoint under `lua/plugins/java.lua` that follows the upstream `lazy.nvim` example: declare `nvim-java` plus its minimal dependencies, run `require("java").setup()`, then enable `jdtls` via `vim.lsp.enable("jdtls")`. Avoid helper modules, keymaps, or local DAP/test customization in this phase.

**Tech Stack:** Neovim Lua config, LazyVim, lazy.nvim, nvim-java, spring-boot.nvim, nui.nvim, nvim-dap

---

## File Structure Map

- Create: `lua/plugins/java.lua`
  Responsibility: the single minimal integration point for `nvim-java` and its upstream-recommended dependencies.
- Modify: `lazy-lock.json`
  Responsibility: record the resolved plugin commits after syncing the new Java-related dependencies.
- Reference: `docs/superpowers/specs/2026-03-21-java-config-migration-phase-2-design.md`
  Responsibility: approved phase 2 migration spec.

### Task 1: Add the Minimal `nvim-java` Plugin Spec

**Files:**
- Create: `lua/plugins/java.lua`

- [ ] **Step 1: Confirm the Java plugin entrypoint does not exist**

Run:

```bash
test ! -f /Users/ifreeky/.config/nvim/lua/plugins/java.lua
```

Expected: exit code `0`.

- [ ] **Step 2: Add the minimal plugin spec**

Create `lua/plugins/java.lua` with:

```lua
return {
  {
    "nvim-java/nvim-java",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
      {
        "JavaHello/spring-boot.nvim",
        commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
      },
    },
    config = function()
      require("java").setup()
      vim.lsp.enable("jdtls")
    end,
  },
}
```

- [ ] **Step 3: Verify the new file content**

Run:

```bash
sed -n '1,200p' /Users/ifreeky/.config/nvim/lua/plugins/java.lua
```

Expected: the file matches the minimal upstream-oriented plugin spec without local keymaps or helper logic.

- [ ] **Step 4: Commit**

```bash
# No commit in this task. Proceed to dependency sync and verification first.
```

### Task 2: Sync Dependencies and Verify Startup

**Files:**
- Verify: `lua/plugins/java.lua`
- Modify: `lazy-lock.json`

- [ ] **Step 1: Sync the new plugin dependencies**

Run:

```bash
nvim --headless "+Lazy! sync" "+qa"
```

Expected: exit code `0`, with the new Java-related plugins resolved into the lockfile.

- [ ] **Step 2: Run the Neovim startup smoke test**

Run:

```bash
nvim --headless "+qa"
```

Expected: exit code `0` with no Lua/module/spec errors.

- [ ] **Step 3: Run a targeted `java` module load check**

Run:

```bash
nvim --headless "+lua require('java')" "+qa"
```

Expected: exit code `0` with no Lua module error.

- [ ] **Step 4: Inspect the resulting working tree**

Run:

```bash
git -C /Users/ifreeky/.config/nvim status --short
```

Expected: shows the new `lua/plugins/java.lua`, the new plan/spec docs for phase 2, and any `lazy-lock.json` update caused by `Lazy! sync`.

- [ ] **Step 5: Commit**

```bash
git -C /Users/ifreeky/.config/nvim add lua/plugins/java.lua lazy-lock.json docs/superpowers/specs/2026-03-21-java-config-migration-phase-2-design.md docs/superpowers/plans/2026-03-21-java-config-migration-phase-2.md
git -C /Users/ifreeky/.config/nvim commit -m "feat(nvim): 接入最小版 nvim-java 配置"
```

Expected: only perform this step if the user explicitly asks for a commit in this session.
