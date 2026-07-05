## Why

The current plugin scaffold is tied to Codex naming and only loosely defines the user-facing behavior. We want a small, vendor-neutral MVP that summarizes selected code through a configurable AI CLI while staying fast, token-conscious, and friendly to LazyVim and standard Neovim users.

## What Changes

- Rename the product direction to `ai-summary.nvim` with `require("ai-summary")` as the Lua module namespace.
- Provide a command-first MVP through `:AISummary` without installing a default keymap.
- Send the selected range plus focused repository metadata to a configurable AI CLI provider.
- Default to Codex CLI through `{ "codex", "exec", "-" }`, while shaping configuration so Claude Code, Opencode, or other providers can be added later.
- Display streaming Markdown output in a floating window with a fixed response format.
- Add timeout handling with a default of 60 seconds.
- Include lightweight language, file, range, root, and project hints to help the provider search only when needed.

## Capabilities

### New Capabilities
- `ai-summary-command`: Summarize a Visual selection through a configurable AI CLI provider and display the result in Neovim.

### Modified Capabilities

## Impact

- Affected Lua plugin modules: command setup, configuration, selection metadata, CLI runner, prompt construction, and floating output UI.
- README will document LazyVim/lazy.nvim and native package installation.
- No new runtime dependency is required beyond Neovim and the configured external CLI provider.
