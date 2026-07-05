## ADDED Requirements

### Requirement: Command summarizes a Visual selection
The plugin SHALL provide an `:AISummary` command that summarizes the current Visual selection through the configured AI CLI provider.

#### Scenario: Visual selection is summarized
- **WHEN** the user selects code in Visual mode and runs `:AISummary`
- **THEN** the plugin sends the selected code and summary prompt to the configured provider

#### Scenario: Empty selection is rejected
- **WHEN** the command is run without selected code
- **THEN** the plugin warns the user and does not start the provider process

### Requirement: Prompt includes focused repository context
The plugin SHALL include focused metadata with the selected code so the provider can inspect external references from the correct repository context without receiving the full buffer by default.

#### Scenario: Prompt includes selection metadata
- **WHEN** the plugin builds a provider prompt
- **THEN** the prompt includes repository root or cwd, current file path, filetype or language, file extension, and selected line range

#### Scenario: Prompt constrains provider exploration
- **WHEN** the plugin builds a provider prompt
- **THEN** the prompt instructs the provider to prioritize the selected code, inspect external references only when needed, and avoid modifying files

#### Scenario: Prompt handles conflicting language hints
- **WHEN** editor metadata conflicts with the selected code
- **THEN** the prompt instructs the provider to treat metadata as hints and infer language or framework from the selected code and repository files

### Requirement: Provider configuration is vendor-neutral
The plugin SHALL configure AI providers through vendor-neutral options while defaulting to Codex CLI.

#### Scenario: Default provider is used
- **WHEN** setup is called without provider overrides
- **THEN** the plugin uses the `codex` provider with command `{ "codex", "exec", "-" }`

#### Scenario: Provider command is overridden
- **WHEN** the user configures a provider command
- **THEN** the plugin runs the configured command for summaries

### Requirement: Summary output is displayed in Neovim
The plugin SHALL display provider output in a native floating Markdown window.

#### Scenario: Provider output streams into the window
- **WHEN** the provider writes stdout or stderr
- **THEN** the plugin appends the output to the floating window

#### Scenario: User closes the output window
- **WHEN** the user presses `q` in the summary window
- **THEN** the plugin closes the floating window

### Requirement: Provider failures are visible
The plugin SHALL surface provider startup failures, non-zero exits, and timeouts to the user.

#### Scenario: Provider command cannot start
- **WHEN** the configured provider command cannot be started
- **THEN** the plugin displays a clear failure message

#### Scenario: Provider exits with an error
- **WHEN** the provider exits with a non-zero code
- **THEN** the plugin displays the exit code in the output window

#### Scenario: Provider exceeds timeout
- **WHEN** the provider runs longer than the configured timeout
- **THEN** the plugin stops the provider job and displays a timeout message

### Requirement: Command has no default keymap
The plugin SHALL create `:AISummary` without installing a default keymap.

#### Scenario: Setup creates command only
- **WHEN** the plugin is set up with default options
- **THEN** `:AISummary` is available and no default mapping is installed
