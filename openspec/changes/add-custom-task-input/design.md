## Context

The current `:AISummary` path validates and extracts a Visual selection, builds repository context, calls the configured `prompt(code, context)` function, and immediately starts the provider. The built-in prompt always requests a summary with fixed Markdown sections and explicitly prohibits write operations. The plugin has no input UI or chat state, and custom prompt callbacks are part of its public configuration surface.

The new interaction must fit this asynchronous command path without adding a UI dependency, changing provider commands, weakening the read-only boundary, or breaking existing two-argument prompt callbacks.

## Goals / Non-Goals

**Goals:**

- Ask for an optional, single-request task after confirming that selected code exists.
- Treat empty and whitespace-only input as the existing summary request.
- Route non-empty input through a task-oriented prompt that retains repository metadata and selected code.
- Make cancellation side-effect free: no output window and no provider process.
- Preserve compatibility with configured prompt callbacks.

**Non-Goals:**

- Multi-turn chat, task history, or persisted input.
- Multiline task editing or a plugin-owned custom input window.
- Applying patches, modifying repository files, or bridging AI actions back into Neovim.
- Changing provider command construction, sandbox flags, model selection, or timeout behavior.

## Decisions

### Use `vim.ui.input` as the task boundary

After selection validation and extraction, `summarize_range` will call `vim.ui.input` with a prompt that explains that an empty value performs the default summary. Once a value is submitted, provider resolution, context construction, output-window creation, and process startup will be scheduled for the next event-loop turn. This lets third-party input UIs finish restoring editor state before the plugin opens and focuses its output window.

This uses Neovim's native abstraction and automatically respects user-installed UI implementations without adding a dependency. A custom floating input component was considered, but it would duplicate editor UI behavior and expand the maintenance surface. Accepting task text as a command argument was also considered, but Visual-range command parsing and shell-like quoting would be less approachable and would not provide the requested input box.

### Give cancellation and empty submission distinct semantics

A `nil` callback value means the input UI was cancelled and stops the flow silently. A submitted value is trimmed for classification: an empty result selects the legacy summary path, while a non-empty result becomes the task. Trimming avoids treating accidental whitespace as a custom task.

Cancellation is not mapped to the default summary because pressing Escape should not unexpectedly spend provider time or open an output window.

### Extend the prompt callback compatibly

The prompt callback will be invoked as `prompt(code, context, task)`, where `task` is `nil` for the default-summary path and normalized text for a custom task. Lua functions that declare only the existing `code, context` parameters ignore the extra argument, so current configurations remain valid. Passing the task only through mutable context was considered, but an explicit argument makes the public extension point clearer and avoids mixing user instructions with detected repository metadata.

### Keep separate built-in prompt contracts for summaries and tasks

The empty-task branch will return the current prompt unchanged, including its exact `Summary`, `External References`, and `Notes` sections. The custom-task branch will identify the user task, carry over language and repository metadata, prioritize the selection, allow focused repository inspection, require Markdown output, and retain the prohibition on file changes and write operations. It will not require summary-specific section headings because tasks such as bug review or test-case generation need different answer shapes.

A single template with conditional lines was considered, but separate branches make preserving the existing default contract easier to verify and prevent summary-only output rules from distorting custom answers.

## Risks / Trade-offs

- Every summary now requires one extra confirmation step → Make the empty-input behavior explicit in the prompt so pressing Enter remains fast.
- `vim.ui.input` is single-line in its default implementation → Keep multiline composition out of scope; users can install a compatible UI implementation, and a future change can add a dedicated editor if demand emerges.
- User task text could request file modification despite the feature being read-only → Keep non-modification instructions mandatory in the built-in task envelope and do not add an apply/edit path.
- Custom callbacks may assume exactly two arguments conceptually → Lua ignores surplus positional arguments, and documentation will describe the optional third argument without requiring existing callbacks to change.
- Asynchronous input could accidentally open output or start work after cancellation → Defer all provider and output setup until the callback returns a non-`nil` value and test the cancellation path.
- Some `vim.ui.input` implementations restore the original window after invoking the callback, overriding the output-window focus → Schedule submitted work for the next event-loop turn so input cleanup completes first.
