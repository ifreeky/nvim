# Neovim Config Cleanup Design

## Context

This repository is still structurally close to the default LazyVim layout:

- `lua/config/*` contains the standard entry points.
- `lua/plugins/*` contains plugin specs and custom overrides.

The current pain point is not feature coverage. It is responsibility mixing inside a few custom files. In particular:

- `lua/plugins/persistence.lua` mixes session restore policy, neo-tree opening, buffer feature recovery, and autocmd wiring.
- `lua/plugins/java.lua` mixes Java project detection, `jdtls` command resolution, and multiple plugin integrations.
- `lua/config/keymaps.lua` already contains small implementation helpers in addition to key definitions.

The user wants a cleanup oriented toward maintainability, but chose the light-weight path:

- keep the existing LazyVim-oriented structure;
- improve file responsibility boundaries;
- allow small behavior corrections where they make the startup/load path easier to understand.

## Goals

- Make startup and loading behavior easier to read from the file layout.
- Reduce multi-responsibility plugin files without introducing a new top-level architecture.
- Keep the configuration recognizably aligned with LazyVim conventions.
- Remove obvious template noise that makes it harder to see which files are real customizations.

## Non-Goals

- Do not redesign the entire repository structure.
- Do not replace the current plugin strategy with a different framework or a large set of LazyVim extras.
- Do not broadly rewrite keybindings, theme choices, or day-to-day editing habits.
- Do not introduce abstraction layers unless they reduce an existing concrete maintenance problem.

## Chosen Approach

Use a light-weight cleanup:

1. Keep `lua/config/*` and `lua/plugins/*` as the main organization.
2. Split only the heavy implementation details out of overloaded files.
3. Keep plugin entry files declarative: registration, high-level opts, events, and integration points.
4. Move low-level helper functions into small adjacent helper modules only when doing so makes the main file materially easier to read.

This intentionally stops short of adding a new top-level namespace such as `lua/<custom>/*`.

## Proposed File-Level Changes

### 1. Persistence/session cleanup

Target: `lua/plugins/persistence.lua`

Expected cleanup:

- keep session restore policy in the main plugin file;
- keep autocmd registration in the main plugin file only if it remains readable;
- move pure helper logic out of the file, especially:
  - directory checks;
  - explorer-opening helper;
  - buffer filetype/treesitter restoration details.

The resulting file should explain:

- when a session is restored;
- when neo-tree is opened;
- what post-restore hooks run.

It should no longer bury those answers inside utility details.

### 2. Java configuration cleanup

Target: `lua/plugins/java.lua`

Expected cleanup:

- keep treesitter, mason, conform, and lsp registration in the main file;
- extract Java root detection and `jdtls` command building into small helpers;
- preserve the current behavior around disabling diagnostics and Java-specific `jdtls` settings unless a simplification is clearly safer.

The resulting file should read as plugin wiring, not as a mixed plugin/business-logic script.

### 3. Keymap file cleanup

Target: `lua/config/keymaps.lua`

Expected cleanup:

- keep key definitions grouped by behavior;
- minimize inline implementation code where that improves readability;
- make comments and grouping more intentional so the file reads like a map of interaction choices rather than an accumulation of edits.

This is a cleanup pass, not a keybinding redesign.

### 4. Template residue cleanup

Targets:

- `README.md`
- `lua/plugins/example.lua`

Expected cleanup:

- remove or replace template-only content that no longer describes the real configuration;
- keep only documentation that helps a future reader understand this repository.

## Behavioral Adjustment Boundary

Small behavior changes are allowed only when they directly improve predictability or reduce accidental coupling. Acceptable examples:

- making startup/session restore conditions easier to reason about;
- tightening helper responsibilities so one branch change does not silently affect unrelated behavior;
- removing template artifacts that obscure the active configuration.

Out of scope for this cleanup:

- major keymap redesign;
- plugin swaps;
- theme changes;
- broad UX rethinking;
- migrating to a substantially different project layout.

## Verification Strategy

Verification should stay proportionate to the scope:

- run a headless Neovim startup check to catch Lua/module/spec errors;
- inspect the resulting startup path to confirm the intended files still own the intended responsibilities;
- confirm that heavy files became more readable without spreading logic into hard-to-find locations.

Recommended command:

```bash
nvim --headless "+qa"
```

If additional targeted checks are needed, they should focus on startup/session/plugin loading rather than on unrelated editor behavior.

## Risks

- Over-splitting small config files would make navigation worse instead of better.
- Cleaning up around `persistence.nvim` can accidentally change startup/session behavior if conditions are rewritten carelessly.
- Cleaning up Java setup can break root detection if helper extraction changes path resolution semantics.

The implementation should therefore prefer the smallest structural change that clearly improves readability.

## Expected Outcome

After this cleanup:

- the repository still looks like a LazyVim-based config;
- the main custom plugin files are easier to scan;
- the startup/load path is easier to reason about;
- future edits to session handling or Java support require reading fewer unrelated concerns first.
