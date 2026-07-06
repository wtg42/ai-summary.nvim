## Why

The default Codex provider currently inherits the user's Codex CLI configuration unless the user replaces the raw command manually. The plugin needs per-run Codex defaults that fit short code summaries without modifying the user's global Codex settings.

## What Changes

- Add Codex-only provider options for `model` and `reasoning_effort`.
- Default Codex summaries to `gpt-5.5` with `low` reasoning effort by passing per-run `codex exec` arguments.
- Add a runtime configuration command for viewing and changing Codex model or reasoning effort for the current Neovim session.
- Validate invalid runtime configuration input and show concise usage examples so users can correct typos.
- Keep custom provider commands as an escape hatch and do not auto-map model or effort for non-Codex providers.
- Update README with the new Codex usage, command examples, per-run override behavior, and the current Codex-only support boundary.

## Capabilities

### New Capabilities
- `codex-provider-options`: Configure and adjust Codex provider model and reasoning effort for code summaries.

### Modified Capabilities

## Impact

- Affected Lua modules: provider configuration, command setup, and provider command resolution.
- README will document Codex-only model and reasoning effort support, runtime configuration usage, and custom provider limitations.
- No new runtime dependency is required.
