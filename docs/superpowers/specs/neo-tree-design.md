# Neo-tree Migration Design

## Goal

Bring the `neo-tree` behavior from the portable LazyVim reference config into this Neovim config.

## Context

The current config already uses the standard LazyVim structure:

- plugin specs are loaded from `lua/plugins/*.lua`
- base config is loaded from `lua/config/*.lua`
- `lazyvim.json` exists, but `neo-tree` is not currently enabled or customized

The reference config adds three distinct layers around `neo-tree`:

- `neo-tree` behavior overrides
- `persistence.nvim` startup and session-restore integration
- `bufferline.nvim` visual cleanup for the `neo-tree` offset area

## Scope

In scope:

- enable LazyVim's `editor.neo-tree` extra
- add a dedicated `neo-tree` plugin spec file under `lua/plugins`
- add a dedicated `persistence.nvim` plugin spec file under `lua/plugins`
- add a dedicated `bufferline.nvim` UI override under `lua/plugins`
- replicate the reference behavior for automatic tree opening on directory entry and after session restore

Out of scope:

- changing the colorscheme or other UI plugins
- replacing LazyVim's overall file explorer architecture
- broad keymap changes outside the `neo-tree` window mappings
- unrelated LSP, markdown, or editing behavior

## Recommended Approach

Use three standalone plugin spec files plus the LazyVim `neo-tree` extra.

Why this approach:

- matches the reference config structure closely
- keeps behavior boundaries clear and easy to maintain
- avoids mixing startup/session logic into the tree UI file
- minimizes risk to the rest of the existing config

## Behavior

### Neo-tree

- enable the `lazyvim.plugins.extras.editor.neo-tree` extra
- configure `filesystem.scan_mode = "deep"`
- configure `filesystem.group_empty_dirs = true`
- configure `git_status.group_empty_dirs = true`
- remap `L` to expand all subnodes
- remap `H` to close all subnodes

### Persistence Integration

- on `VimEnter`, only intervene when Neovim starts with:
  - no file arguments
  - exactly one directory argument
- if stdin is used, do nothing
- if a session exists in `persistence.nvim`, load it and then open the left-side filesystem `neo-tree`
- if there is no session but startup target is a directory, open the left-side filesystem `neo-tree`
- after session restore, re-run buffer `FileType` autocommands and restart treesitter for restored file buffers
- if treesitter is not ready yet at session restore time, defer that refresh until `VeryLazy`

### Bufferline UI

- when the `neo-tree` offset is present in `bufferline`, clear its label text
- do not change any other `bufferline` sections or behavior

## Risks And Mitigations

- `neo-tree` may not be loaded at the exact moment the startup callback runs:
  use `pcall(require, "neo-tree.command")` before executing the show action
- restored buffers may miss syntax features immediately after session load:
  explicitly restore `filetype` and treesitter state after `PersistenceLoadPost`
- automatic tree opening could become intrusive for normal file opens:
  restrict the behavior to empty startup and single-directory startup only
- UI regressions in `bufferline`:
  keep the override limited to the `neo-tree` offset label text

## Verification

Verify all of the following after implementation:

1. `neo-tree` is enabled through LazyVim and loads without plugin errors.
2. Starting `nvim` with no arguments restores the session when available and opens the left-side tree.
3. Starting `nvim <directory>` opens the left-side tree even when no session exists.
4. Starting `nvim <file>` does not force-open the tree.
5. Restored buffers regain expected filetype-driven behavior and treesitter highlighting.
6. The `neo-tree` window supports `H` and `L` for close-all and expand-all behavior.
7. `bufferline` no longer shows the extra offset label text for `neo-tree`.
