# Markdown Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add in-editor Markdown preview to this Neovim config using `MeanderingProgrammer/render-markdown.nvim`, with a buffer-local toggle for Markdown files.

**Architecture:** Implement the feature as a standalone Lazy plugin spec under `lua/plugins` so the change stays isolated from the rest of the config. Keep configuration minimal, rely on plugin defaults where reasonable, and expose the official `:RenderMarkdown buf_toggle` command through a Lazy key spec.

**Tech Stack:** LazyVim, lazy.nvim, Neovim Lua config, nvim-treesitter, render-markdown.nvim

---

## File Structure

- Create: `lua/plugins/markdown-preview.lua`
  - Owns plugin installation, dependencies, lazy-loading conditions, plugin options, and the Markdown toggle keymap.
- Modify: `lazy-lock.json`
  - Updated by Lazy after installing the plugin.
- Verify with: headless `nvim` commands and `:RenderMarkdown` plugin command execution.

### Task 1: Add the plugin spec

**Files:**
- Create: `lua/plugins/markdown-preview.lua`

- [ ] **Step 1: Write the plugin spec skeleton**

```lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
```

- [ ] **Step 2: Add minimal, theme-safe options**

```lua
opts = {
  file_types = { "markdown" },
  render_modes = { "n", "c", "t" },
}
```

- [ ] **Step 3: Add a Markdown buffer toggle key**

```lua
keys = {
  {
    "<leader>um",
    "<cmd>RenderMarkdown buf_toggle<cr>",
    ft = "markdown",
    desc = "Toggle Markdown Render",
  },
}
```

- [ ] **Step 4: Save the file and format if needed**

Run: `stylua lua/plugins/markdown-preview.lua`
Expected: exit code `0`

### Task 2: Install and verify the plugin

**Files:**
- Modify: `lazy-lock.json`
- Verify: `lua/plugins/markdown-preview.lua`

- [ ] **Step 1: Install/update plugins**

Run: `nvim --headless "+Lazy! sync" +qa`
Expected: exit code `0`

- [ ] **Step 2: Verify the plugin command exists**

Run: `nvim --headless "+lua vim.cmd('edit README.md')" "+lua vim.cmd('RenderMarkdown get')" +qa`
Expected: exit code `0`

- [ ] **Step 3: Verify the toggle command runs on a Markdown buffer**

Run: `nvim --headless "+lua vim.cmd('edit README.md')" "+lua vim.cmd('RenderMarkdown buf_toggle')" "+lua vim.cmd('RenderMarkdown buf_toggle')" +qa`
Expected: exit code `0`

- [ ] **Step 4: Check resulting workspace changes**

Run: `git status --short`
Expected: new plugin spec file plus any lockfile update from Lazy

### Task 3: Final verification and review

**Files:**
- Verify: `lua/plugins/markdown-preview.lua`
- Verify: `lazy-lock.json`

- [ ] **Step 1: Re-read the spec and compare behavior**

Check:
- Markdown-only activation
- minimal render configuration
- manual toggle available

- [ ] **Step 2: Run final verification commands**

Run: `nvim --headless "+Lazy! sync" "+lua vim.cmd('edit README.md')" "+lua vim.cmd('RenderMarkdown get')" "+lua vim.cmd('RenderMarkdown buf_toggle')" +qa`
Expected: exit code `0`

- [ ] **Step 3: Summarize any limits**

Note:
- headless verification proves command loading, not visual appearance
- visual rendering still needs an interactive Markdown buffer check in a normal Neovim session
