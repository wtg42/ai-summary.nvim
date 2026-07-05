## 1. Rename and Public Entry

- [x] 1.1 Rename Lua module namespace from `codex-summary` to `ai-summary` while preserving the existing module separation.
- [x] 1.2 Rename the user command from `:CodeSummary` to `:AISummary`.
- [x] 1.3 Remove the default keymap behavior so setup creates the command without installing a mapping.
- [x] 1.4 Update README examples to use `ai-summary.nvim`, `require("ai-summary")`, and `:AISummary`.

## 2. Configuration and Provider

- [x] 2.1 Add vendor-neutral provider configuration with default provider `codex`.
- [x] 2.2 Set the default Codex command to `{ "codex", "exec", "-" }`.
- [x] 2.3 Add configurable `timeout_ms` with a default of `60000`.
- [x] 2.4 Support overriding the active provider command through setup options.

## 3. Prompt and Context

- [x] 3.1 Build prompt metadata from repository root or cwd, file path, filetype, file extension, and selected line range.
- [x] 3.2 Add lightweight project hints from common project files without implementing a full detector.
- [x] 3.3 Include response-format instructions for `## Summary`, `## External References`, and `## Notes`.
- [x] 3.4 Instruct the provider to prioritize selected code, inspect external references only when needed, treat metadata as hints, and avoid file modifications.

## 4. Runner and Output

- [x] 4.1 Run the configured provider command from the detected repository root when possible.
- [x] 4.2 Stream stdout and stderr into the floating Markdown window.
- [x] 4.3 Stop the provider job when `timeout_ms` is exceeded and display a timeout message.
- [x] 4.4 Display clear startup failure and non-zero exit messages.
- [x] 4.5 Keep `q` as the floating-window close mapping.

## 5. Verification

- [x] 5.1 Verify `:AISummary` sends selected code and required metadata for a Visual selection.
- [x] 5.2 Verify empty selections warn without starting the provider.
- [x] 5.3 Verify provider command override and timeout behavior.
- [x] 5.4 Verify README covers LazyVim/lazy.nvim and native package installation.
