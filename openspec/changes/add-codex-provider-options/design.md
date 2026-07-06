## Context

The plugin currently treats providers as raw command arrays and defaults Codex to `codex exec -`. That keeps the runner generic, but it also means Codex summaries inherit whatever model and reasoning effort the user configured for interactive Codex CLI usage.

For this plugin, the common path is a short selected-code summary. Codex should run with a predictable per-invocation model and low reasoning effort without writing to `~/.codex/config.toml` or changing how the user runs Codex directly.

## Goals / Non-Goals

**Goals:**
- Add Codex provider options for model and reasoning effort.
- Default Codex summaries to `gpt-5.5` and `low` reasoning effort for each plugin invocation.
- Let users override Codex model and reasoning effort through setup options.
- Let users adjust Codex model and reasoning effort at runtime for the current Neovim session.
- Show actionable usage examples when runtime configuration input is invalid.
- Document that model and reasoning effort support is currently Codex-only.

**Non-Goals:**
- No provider-specific adapter for Claude Code, Gemini, opencode, aider, or other AI CLIs in this change.
- No writes to user Neovim config or Codex CLI config files.
- No automatic model or effort argument mapping when a user supplies a raw `cmd`.
- No persistent runtime configuration across Neovim restarts.

## Decisions

- Keep `providers.<name>.cmd` as the escape hatch. If a provider has a configured `cmd`, the plugin runs it exactly as provided. Alternative considered: append model and effort flags to custom commands. That is risky because users may already include their own flags, and non-Codex CLIs use different argument conventions.
- Add Codex-specific options under `providers.codex`. Alternative considered: top-level `model` and `reasoning_effort`. Keeping them under the provider matches the existing provider table and avoids implying that all providers support the same semantic options.
- Build the default Codex command from options instead of storing a static command array. The resolved command should be equivalent to `codex exec -m <model> -c model_reasoning_effort="<effort>" -`. This gives the plugin per-run defaults without modifying Codex global settings.
- Use `low` as the default reasoning effort. Alternative considered: `medium`. Most summaries prioritize speed and cost; users can opt into `medium` when the selected code depends on broader repository context.
- Add a separate `:AISummaryConfig` command for runtime configuration. Alternative considered: extending `:AISummary` subcommands. A separate command keeps the range-based summary command focused and avoids ambiguity with Visual selections.
- Runtime command changes only update in-memory configuration for the current Neovim process. Alternative considered: writing back to config files. Runtime persistence would require choosing a user-owned config target and risks surprising edits.

## Risks / Trade-offs

- Codex model names may change over time -> keep the default isolated in configuration and document user override examples.
- Users may expect `model` to apply to custom providers -> README and validation messages will state that built-in model and effort handling currently applies only to Codex.
- A misspelled reasoning effort could silently degrade behavior -> validate allowed values and keep the previous value unchanged when input is invalid.
- Runtime configuration adds command surface area -> provide `:AISummaryConfig show` and command completion so the available operations are discoverable.
