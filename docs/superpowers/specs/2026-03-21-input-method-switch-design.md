# Neovim Input Method Auto-Switch Design

## Context

This Neovim config currently has no input method switching logic. The repository follows a light-weight LazyVim layout:

- `lua/config/autocmds.lua` is the intended place for custom autocmd behavior.
- `lua/config/keymaps.lua` holds explicit key definitions.
- `lua/plugins/*` is used for plugin specs and higher-level integrations.

The requested behavior is editor-mode driven on macOS:

- when leaving insert mode, switch to an English input method;
- when returning to insert mode, restore the input method that was active before leaving insert mode.

The user chose an external tool based approach over AppleScript and selected `macism` as the target tool.

## Goals

- Automatically switch to English when leaving insert mode.
- Restore the previously active input method when re-entering insert mode.
- Keep the implementation small and local to the existing config structure.
- Fail safely when the external tool is unavailable or returns an unexpected value.

## Non-Goals

- Do not add a plugin just for input method switching.
- Do not redesign keymaps or mode behavior outside insert/normal transitions.
- Do not handle command-line mode, terminal mode, or other mode families in this iteration.
- Do not add notifications, UI prompts, or logging unless needed to debug a real failure.

## Chosen Approach

Use `macism` directly from Neovim autocmds.

This keeps the behavior dependency explicit:

- Neovim decides when mode transitions happen.
- `macism` reads and sets the system input method by input source ID.

No additional plugin layer is needed for this first version.

## Design

### Placement

Implement the behavior in `lua/config/autocmds.lua`.

This file is already the repository's extension point for editor lifecycle behavior, and the requested feature is an autocmd-driven mode transition policy rather than a plugin integration.

Register the autocmds in a dedicated augroup with `clear = true` so the behavior remains reload-safe and does not duplicate handlers if the file is re-sourced during config development.

### State Handling

Keep one module-local variable for the last non-English input source ID.

Behavior:

- On `InsertLeave`, read the current input source ID through `macism`.
- If that ID is not the configured English input source ID, store it as the last restore target.
- Then switch to the configured English input source ID.

- On `InsertEnter`, if a previously stored non-English input source ID exists, switch back to it.

Manual input method changes made while already in normal mode are intentionally ignored in this first version. The restore target is only updated at `InsertLeave`, which keeps the state model simple and aligned with the requested workflow.

This preserves the user's prior insert-mode input method instead of forcing a fixed Chinese input method.

### English Input Source

Use `com.apple.keylayout.ABC` as the default English input source ID.

This is the common macOS English layout and matches the intended "leave insert mode -> back to English" workflow. If the user's machine uses a different English layout such as `U.S.`, that value can be adjusted later without changing the overall design.

### Error Handling

The implementation should be silent on operational failures:

- if `macism` is not executable from Neovim's environment, skip all switching logic;
- if reading the current input source fails, do not overwrite the stored restore target;
- if setting the target input source fails, do not raise an editor error.

This is a convenience feature. It must not interrupt editing.

### `macism` Invocation Contract

The implementation should treat `macism` as a simple shell command with this contract:

- `macism` with no argument returns the current input source ID on stdout when successful;
- `macism <input-source-id>` switches to the given input source ID and should be considered successful only if the shell exit code is `0`;
- any non-zero exit code or empty read result should be treated as a no-op failure path.

The config should check executability once before registering behavior so Neovim does not repeatedly attempt unavailable commands.

## Verification Strategy

Because this repository is a config repo without a dedicated automated test harness, verification will be lightweight:

- confirm `macism` is executable from the same shell environment that launches Neovim;
- run a headless Neovim startup check to catch Lua/autocmd errors;
- run a Lua-level smoke check that loads the config file successfully.

Recommended checks:

```bash
command -v macism
nvim --headless "+qa"
```

Manual verification after implementation:

1. Launch Neovim from a shell where `macism` is on `PATH`.
2. Enter insert mode while using a non-English input method.
3. Leave insert mode and confirm the system input method changes to `ABC`.
4. Re-enter insert mode and confirm the prior non-English input method is restored.

## Risks

- `macism` may be installed but unavailable in the environment used to launch Neovim.
- The configured English input source ID may differ from the actual English layout enabled on this machine.
- Some users may later expect the behavior in command-line mode or terminal buffers, which is intentionally out of scope for this first pass.

## Expected Outcome

After implementation:

- normal mode returns to English input reliably;
- insert mode restores the user's previously active non-English input method;
- the feature remains a small local config behavior with no plugin dependency beyond the external `macism` binary.
