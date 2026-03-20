# Markdown Preview Design

## Goal

Add in-editor Markdown preview to this LazyVim-based Neovim config using `MeanderingProgrammer/render-markdown.nvim`.

## Context

The current config uses the standard LazyVim structure:

- plugin specs are loaded from `lua/plugins/*.lua`
- `nvim-treesitter` is already part of the stack
- the active colorscheme is `NeoSolarized`

The user explicitly wants in-editor rendering rather than browser-based preview.

## Scope

In scope:

- add a dedicated plugin spec file under `lua/plugins`
- install and configure `render-markdown.nvim`
- enable rendering for Markdown buffers
- provide a simple toggle command/key for switching between rendered and raw Markdown

Out of scope:

- browser preview
- live HTML export
- broad visual restyling beyond basic compatibility with the current colorscheme
- enabling the renderer for non-Markdown filetypes unless later requested

## Recommended Approach

Use a standalone Lazy plugin spec file for `render-markdown.nvim` with a dependency on `nvim-treesitter`.

Why this approach:

- fits the existing LazyVim layout cleanly
- keeps the change isolated and easy to revert
- avoids adding Node/browser dependencies
- gives a useful reading/editing experience without changing the rest of the setup

## Behavior

- the plugin loads for Markdown buffers
- base rendering features stay enabled for headings, lists, block quotes, and code blocks
- configuration remains light to reduce theme conflicts with `NeoSolarized`
- a manual toggle is exposed so the user can inspect raw Markdown syntax when needed

## Risks And Mitigations

- theme highlight mismatches: start with minimal styling and rely on defaults
- plugin command/key mismatch: wire the toggle to the plugin's documented API/commands only after checking current upstream usage
- unintended filetype spillover: restrict activation to Markdown

## Verification

Verify all of the following after implementation:

1. `:Lazy` recognizes and installs the plugin without errors.
2. Opening a Markdown file shows rendered elements in the editor.
3. The toggle works without throwing Lua or command errors.
4. Existing non-Markdown buffers behave unchanged.
