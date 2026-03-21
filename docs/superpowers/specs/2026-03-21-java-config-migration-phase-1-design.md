# Java Config Migration Phase 1 Design

## Context

This Neovim config is a LazyVim-based setup with custom plugin specs under `lua/plugins/*` and helper modules under `lua/config/helpers/*`.

The current Java support is intentionally light:

- `lua/plugins/java.lua` adds Java treesitter support, Mason packages, Java formatting, and `jdtls` server configuration.
- `lua/config/helpers/java.lua` provides Java project root detection for Maven and Gradle projects.

The user has decided to migrate to `nvim-java`, but wants to do it in two phases. Phase 1 is removal only. It should delete the current `nvim-jdtls`-style setup first, even if Java support temporarily drops to zero.

## Goals

- Remove the current Java-specific Neovim configuration cleanly.
- Leave the repository in a state where no Java plugin wiring or Java helper module remains active.
- Keep the rest of the Neovim configuration working exactly as before.
- Prepare the repository for a separate Phase 2 that introduces `nvim-java`.

## Non-Goals

- Do not introduce `nvim-java` in this phase.
- Do not preserve partial Java editing support.
- Do not add compatibility shims for the old Java setup.
- Do not refactor unrelated plugin files or general repository structure.

## Chosen Approach

Use a clean removal instead of a soft-disable:

1. Delete `lua/plugins/java.lua`.
2. Delete `lua/config/helpers/java.lua`.
3. Verify that no active configuration still references `jdtls`, Java helper modules, or Java-specific plugin wiring.
4. Run a headless Neovim startup check to confirm that removing the Java files does not break startup.

This is preferred over soft-disabling because the user explicitly wants the old Java path gone before adding the new one. Keeping dead Java configuration in place would increase ambiguity during the later `nvim-java` adoption.

## File-Level Changes

### 1. Remove Java plugin wiring

Target: `lua/plugins/java.lua`

This file currently owns:

- Java treesitter registration
- Mason package installation for `jdtls` and `google-java-format`
- Conform formatter registration for Java
- `nvim-lspconfig` setup for `jdtls`

In Phase 1, the file should be deleted entirely.

### 2. Remove Java helper module

Target: `lua/config/helpers/java.lua`

This file currently owns Java project root detection helpers used by the old `jdtls` config.

In Phase 1, the file should be deleted entirely because it has no remaining purpose once the old Java plugin file is removed.

### 3. Leave non-Java configuration untouched

Targets intentionally not changed:

- `lua/config/*` outside the Java helper
- all non-Java plugin files
- general LazyVim/bootstrap setup
- unrelated lockfile changes already present in the working tree

This keeps the migration boundary explicit and reduces the risk of mixing Java migration work with unrelated cleanup.

## Behavioral Outcome

After Phase 1:

- opening Java files will no longer activate custom Java LSP, formatting, or treesitter installation logic from this repository;
- Mason will no longer ensure `jdtls` or `google-java-format` through this config;
- the repository will have no local Java helper module;
- Neovim startup should still work normally for all non-Java workflows.

This temporary loss of Java support is intentional and accepted by the user.

## Risks

- Another file could still reference the removed Java helper or Java plugin assumptions.
- Removing the Java plugin file could surface an unexpected dependency on Java-specific configuration during startup.
- `lazy-lock.json` is already modified in the working tree, so the implementation must avoid accidentally rewriting unrelated lockfile state during the removal step.

## Verification Strategy

Verification should stay minimal and directly tied to this phase:

- confirm no repository files still reference `config.helpers.java` or `jdtls` as active configuration;
- run a headless Neovim startup smoke test to catch missing-module or plugin-spec errors.

Recommended command:

```bash
nvim --headless "+qa"
```

Optional repository checks:

```bash
rg -n "config\\.helpers\\.java|jdtls|google-java-format" lua
```

## Expected Outcome

Phase 1 should end with a cleanly removed old Java integration and a stable Neovim startup path. The repository should then be ready for a separate Phase 2 that adds `nvim-java` from a clean baseline instead of layering it on top of the previous `jdtls` setup.
