# Java Config Migration Phase 2 Design

## Context

Phase 1 removed the previous Java setup based on a hand-written `jdtls` integration. The repository is now intentionally at a zero-Java-support baseline.

The next step is to adopt `nvim-java` for Maven and Spring Boot development. The user wants this phase to stay as close as possible to the official minimum setup:

- no custom keymaps yet;
- no extra DAP customization;
- no early runtime overrides for JDK selection;
- no attempt to preserve the old Java configuration shape.

The user's Java toolchain version switching is already handled by `direnv`, so this phase should avoid duplicating that responsibility unless `nvim-java` requires it.

## Goals

- Reintroduce Java support through `nvim-java` using the official minimal setup pattern.
- Keep the plugin wiring small and easy to replace or extend later.
- Ensure the config supports the user's Maven and Spring Boot workflow baseline.
- Avoid layering the new setup on top of any legacy `jdtls` configuration.

## Non-Goals

- Do not add custom Java keymaps in this phase.
- Do not add custom debug adapter configuration in this phase.
- Do not add project-specific JDK runtime lists in this phase.
- Do not add extra helper modules unless the minimal setup proves insufficient.
- Do not customize test runner, Spring profile UI, or Java commands beyond what `nvim-java` provides by default.

## Chosen Approach

Use the official `lazy.nvim` installation pattern for `nvim-java`:

1. Create a new `lua/plugins/java.lua`.
2. Register `nvim-java/nvim-java` with the dependencies required by the official minimal installation:
   - `MunifTanjim/nui.nvim`
   - `mfussenegger/nvim-dap`
   - `JavaHello/spring-boot.nvim` pinned to the commit shown in the official example
3. In the plugin `config`, call:
   - `require("java").setup()`
   - `vim.lsp.enable("jdtls")`
4. Do not add additional `jdtls` configuration unless startup verification shows the default path is insufficient.

This keeps the setup aligned with upstream guidance and avoids premature customization. Even though the user does not want to actively use DAP yet, `nvim-java` includes `nvim-dap` in its official minimal dependency set, so this phase should follow that baseline rather than introducing an unverified local deviation.

## File-Level Changes

### 1. Add Java plugin entrypoint

Target: `lua/plugins/java.lua`

This file should contain only the minimal plugin spec needed to enable `nvim-java` in this repository. It should act as a declarative integration point, not as a custom Java framework.

Expected responsibilities:

- declare `nvim-java` and its official minimal dependencies;
- run `require("java").setup()`;
- enable the `jdtls` LSP via `vim.lsp.enable("jdtls")`.

The file should not add bespoke keymaps, root detection helpers, formatter overrides, or per-project logic in this phase.

### 2. Leave the rest of the config unchanged

Targets intentionally not changed:

- `lua/config/*`
- all existing non-Java plugin files
- `lazyvim.json`
- any project-specific Java environment management outside Neovim

This keeps the migration small and ensures future Java-specific customization has a clear starting point.

## Behavioral Outcome

After Phase 2:

- opening Java files should use `nvim-java`'s default integration path;
- `jdtls` should be enabled through the new plugin entrypoint;
- the built-in `nvim-java` Spring Boot and Java command set should become available without extra local wrappers;
- the configuration should remain minimal, with no user-defined Java keymaps or custom debug/test wiring yet.

The result is intentionally a baseline, not a finished Java UX.

## Risks

- `nvim-java` may assume plugin versions or startup order that differ slightly from this repository's current plugin mix.
- Because the user relies on `direnv` for JDK and Maven switching, `nvim-java` behavior still depends on Neovim being started from an environment where `direnv` has already applied the correct variables.
- Pinning `spring-boot.nvim` to the official example commit reduces drift but may still interact with future lockfile updates.

## Verification Strategy

Verification should focus on startup and module wiring:

- sync/install the new plugin dependencies;
- run a headless Neovim startup check;
- confirm the `java` module loads during startup without Lua errors.

Recommended commands:

```bash
nvim --headless "+Lazy! sync" "+qa"
nvim --headless "+qa"
```

If a more targeted check is needed:

```bash
nvim --headless "+lua require('java')" "+qa"
```

## Expected Outcome

Phase 2 should restore Java support through a small `nvim-java` plugin spec that matches upstream guidance. After that baseline is stable, follow-up work can add custom keymaps, debug preferences, runtime selection helpers, or project-specific refinements only where they prove necessary.
