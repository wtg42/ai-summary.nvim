## 1. Codex Provider Options

- [x] 1.1 Add Codex provider defaults for `model = "gpt-5.5"` and `reasoning_effort = "low"`.
- [x] 1.2 Resolve the default Codex command from provider options as `codex exec -m <model> -c model_reasoning_effort="<effort>" -`.
- [x] 1.3 Preserve custom `providers.codex.cmd` behavior so configured commands run exactly as provided.
- [x] 1.4 Validate Codex reasoning effort values and avoid silently accepting misspellings.

## 2. Runtime Configuration Command

- [x] 2.1 Add `:AISummaryConfig show` to display active provider and effective Codex model/effort when applicable.
- [x] 2.2 Add `:AISummaryConfig model <model>` to update the current Neovim session's Codex model.
- [x] 2.3 Add `:AISummaryConfig effort <effort>` to update the current Neovim session's Codex reasoning effort.
- [x] 2.4 Show actionable usage examples for unknown subcommands, missing arguments, and invalid effort values.
- [x] 2.5 Add command completion for `show`, `model`, `effort`, and allowed effort values.

## 3. Documentation

- [x] 3.1 Update README setup examples to show Codex `model` and `reasoning_effort`.
- [x] 3.2 Document that Codex model/effort are per-run CLI overrides and do not modify Codex global config.
- [x] 3.3 Document `:AISummaryConfig` usage examples.
- [x] 3.4 Document that built-in model/effort mapping currently supports Codex only, while other AI CLIs must use custom `cmd` until provider-specific adapters are planned.

## 4. Verification

- [x] 4.1 Verify the default Codex command includes `gpt-5.5` and `low` effort.
- [x] 4.2 Verify setup overrides change the generated Codex command.
- [x] 4.3 Verify custom `cmd` is not modified by model/effort options.
- [x] 4.4 Verify invalid runtime command input shows examples and leaves existing values unchanged.
- [x] 4.5 Verify README documents the new behavior and Codex-only support boundary.
