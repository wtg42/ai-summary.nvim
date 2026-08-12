## ADDED Requirements

### Requirement: Command requests an optional task for selected code
The plugin SHALL request an optional per-invocation AI task after `:AISummary` confirms that the Visual selection contains non-whitespace code.

#### Scenario: Valid selection opens task input
- **WHEN** the user runs `:AISummary` with a non-empty Visual selection
- **THEN** the plugin opens an input prompt that identifies empty submission as the default summary action

#### Scenario: Invalid selection does not open task input
- **WHEN** the user runs `:AISummary` without non-whitespace selected code
- **THEN** the plugin warns the user without opening the task input or starting the provider

### Requirement: Empty task preserves default summary behavior
The plugin SHALL use the existing built-in summary prompt and response format when the submitted task is empty or contains only whitespace.

#### Scenario: User submits an empty task
- **WHEN** the user submits an empty task value
- **THEN** the provider receives the selected code through the existing summary prompt

#### Scenario: User submits a whitespace-only task
- **WHEN** the user submits a task containing only whitespace
- **THEN** the provider receives the same prompt it would receive for an empty task

### Requirement: Custom task produces a focused read-only prompt
The plugin SHALL include a normalized non-empty task, selected code, language preference, and focused repository metadata in a task-specific prompt that prohibits file modifications and write operations.

#### Scenario: User submits a custom analysis task
- **WHEN** the user submits `Find possible race conditions` for selected code
- **THEN** the provider receives that task with the selected code and its repository context
- **AND** the prompt requires a read-only Markdown response without enforcing summary-specific section headings

#### Scenario: Custom task contains surrounding whitespace
- **WHEN** the user submits a non-empty task with surrounding whitespace
- **THEN** the provider receives the trimmed task text

### Requirement: Cancelling task input stops the request
The plugin SHALL treat dismissal of the task input as cancellation rather than as an empty task.

#### Scenario: User cancels task input
- **WHEN** the input callback returns no value
- **THEN** the plugin does not open the output window and does not start a provider process

### Requirement: Submitted task focuses the output window
The plugin SHALL open and focus the output window after the task input UI has finished restoring editor state so the window-local close mapping is immediately usable.

#### Scenario: Input UI restores the previous window
- **WHEN** the user submits a task through a `vim.ui.input` implementation that restores the previous window after invoking its callback
- **THEN** the plugin opens the output window after that restoration completes
- **AND** pressing `q` closes the focused output window

### Requirement: Custom prompt callbacks can receive the task compatibly
The plugin SHALL pass the optional normalized task as a third argument to the configured prompt callback while preserving existing callbacks that accept only code and context.

#### Scenario: Task-aware callback receives a custom task
- **WHEN** a configured prompt callback accepts `code`, `context`, and `task` and the user submits a non-empty task
- **THEN** the callback receives the normalized task as its third argument

#### Scenario: Existing callback remains usable
- **WHEN** a configured prompt callback accepts only `code` and `context`
- **THEN** default-summary and custom-task requests can invoke it without requiring a configuration change
