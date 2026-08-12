## Why

`:AISummary` currently sends every Visual selection through one fixed summarization workflow, so users cannot ask the AI to review the same code for a specific concern without leaving Neovim or replacing the configured prompt globally. A per-invocation task input keeps the existing quick summary behavior while making the command useful for focused, read-only code analysis.

## What Changes

- Prompt for an optional AI task whenever `:AISummary` is run with a non-empty Visual selection.
- Preserve the current summary prompt and output contract when the submitted task is empty or whitespace-only.
- Build a task-specific prompt when the user supplies text, while retaining selected-code and repository context and prohibiting file modifications.
- Cancel the request without starting the provider when the input UI is dismissed.
- Keep existing custom prompt callbacks compatible while exposing the optional task to callbacks that choose to use it.
- Document and test the default, custom-task, and cancellation flows.

## Capabilities

### New Capabilities

- `custom-task-input`: Collect an optional per-request task for selected code and route it to either the existing summary behavior or a focused read-only AI task.

### Modified Capabilities

None.

## Impact

- Affected Lua modules: command orchestration and prompt construction in `lua/ai-summary/init.lua` and `lua/ai-summary/config.lua`.
- User-facing behavior: `:AISummary` gains an asynchronous input step before provider execution.
- Documentation and programmatic tests must cover input handling and prompt selection.
- No new runtime dependency, provider command change, or direct file-editing capability is introduced.
