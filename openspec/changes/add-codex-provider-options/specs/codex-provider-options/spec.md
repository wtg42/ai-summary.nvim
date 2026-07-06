## ADDED Requirements

### Requirement: Codex provider has per-run defaults
The plugin SHALL provide Codex provider defaults for model and reasoning effort and SHALL pass them as per-run `codex exec` arguments without modifying the user's Codex CLI configuration files.

#### Scenario: Default Codex command includes model and effort
- **WHEN** setup is called without provider overrides
- **THEN** the plugin runs Codex summaries with model `gpt-5.5` and reasoning effort `low`

#### Scenario: Codex defaults are per invocation
- **WHEN** the plugin runs a Codex summary
- **THEN** the plugin passes model and reasoning effort through command arguments for that provider process
- **THEN** the plugin does not write to Codex CLI configuration files

### Requirement: Codex provider options are configurable
The plugin SHALL allow users to configure the Codex provider model and reasoning effort through setup options.

#### Scenario: User configures Codex model
- **WHEN** the user sets `providers.codex.model`
- **THEN** the plugin uses that model for generated Codex summary commands

#### Scenario: User configures Codex reasoning effort
- **WHEN** the user sets `providers.codex.reasoning_effort`
- **THEN** the plugin uses that reasoning effort for generated Codex summary commands

#### Scenario: Custom provider command is respected
- **WHEN** the user configures `providers.codex.cmd`
- **THEN** the plugin runs that command exactly as configured
- **THEN** the plugin does not automatically append model or reasoning effort arguments

### Requirement: Runtime Codex configuration is adjustable
The plugin SHALL provide a Neovim command for showing and changing Codex model and reasoning effort for the current Neovim session.

#### Scenario: Runtime configuration is shown
- **WHEN** the user runs `:AISummaryConfig show`
- **THEN** the plugin displays the active provider and effective Codex model and reasoning effort when applicable

#### Scenario: Runtime model is changed
- **WHEN** the user runs `:AISummaryConfig model gpt-5.5`
- **THEN** subsequent Codex summaries in the current Neovim session use `gpt-5.5`

#### Scenario: Runtime reasoning effort is changed
- **WHEN** the user runs `:AISummaryConfig effort medium`
- **THEN** subsequent Codex summaries in the current Neovim session use `medium` reasoning effort

#### Scenario: Runtime configuration is not persisted
- **WHEN** the user changes model or reasoning effort with `:AISummaryConfig`
- **THEN** the plugin updates only the current Neovim process configuration

### Requirement: Invalid runtime configuration is actionable
The plugin SHALL validate runtime configuration input and show a usage example when the input is invalid.

#### Scenario: Invalid subcommand shows usage
- **WHEN** the user runs an unknown `:AISummaryConfig` subcommand
- **THEN** the plugin shows supported command examples

#### Scenario: Invalid reasoning effort shows allowed values
- **WHEN** the user runs `:AISummaryConfig effort midum`
- **THEN** the plugin leaves the current reasoning effort unchanged
- **THEN** the plugin shows usage examples and the allowed reasoning effort values

#### Scenario: Missing model argument shows usage
- **WHEN** the user runs `:AISummaryConfig model` without a model value
- **THEN** the plugin leaves the current model unchanged
- **THEN** the plugin shows a model configuration example

### Requirement: Documentation states Codex-only option support
The README SHALL document the Codex provider model and reasoning effort options, runtime configuration commands, and the current support boundary for other AI CLIs.

#### Scenario: README documents Codex setup
- **WHEN** a user reads the configuration section
- **THEN** the README shows how to configure `providers.codex.model` and `providers.codex.reasoning_effort`

#### Scenario: README documents runtime commands
- **WHEN** a user reads the command usage section
- **THEN** the README shows `:AISummaryConfig show`, model, and effort examples

#### Scenario: README documents non-Codex boundary
- **WHEN** a user reads provider documentation
- **THEN** the README states that built-in model and reasoning effort mapping currently supports Codex only and other AI CLIs must use custom `cmd` configuration
