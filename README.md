# ai-summary.nvim

Quickly summarize selected code in Neovim by sending focused context to an AI CLI provider.

This is an early plugin scaffold for local development with LazyVim / lazy.nvim.

## Install locally with LazyVim

Create a file such as `~/.config/nvim/lua/plugins/ai-summary.lua`:

```lua
return {
  {
    dir = "/Users/shiweiting/ai-summary.nvim",
    name = "ai-summary.nvim",
    cmd = { "AISummary", "AISummaryConfig" },
    opts = {
      provider = "codex",
      providers = {
        codex = {
          model = "gpt-5.5",
          reasoning_effort = "low",
        },
      },
      timeout_ms = 60000,
    },
  },
}
```

Then restart Neovim or run:

```vim
:Lazy reload ai-summary.nvim
```

## Install with native packages

```bash
git clone https://github.com/your-name/ai-summary.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/ai-summary.nvim
```

Then call setup from your Neovim config:

```lua
require("ai-summary").setup()
```

## Usage

Select code in Visual mode, then run:

```vim
:AISummary
```

The selected code is sent to the configured provider with file, range, language,
project-root, and lightweight project hints. Output streams into a floating
Markdown window. Press `q` in the summary window to close it.

For Codex CLI, progress and transcript output on stderr is hidden on successful
runs; stderr is shown only when the provider exits with an error.

To reopen the most recent successful summary in the current Neovim session:

```vim
:AISummary last
```

The last summary is stored only in plugin memory for the current Neovim process.
It is not written to disk and disappears after restarting Neovim or reloading the
module.

The plugin does not install a default keymap. Add one in your own config if you
want a shortcut.

## Runtime configuration

Runtime configuration commands do not require a Visual selection. Run them from
Normal mode:

Show the active provider settings:

```vim
:AISummaryConfig show
```

Change the Codex model or reasoning effort for the current Neovim session:

```vim
:AISummaryConfig model gpt-5.5
:AISummaryConfig effort low
:AISummaryConfig effort medium
```

Allowed reasoning effort values are:

```text
minimal, low, medium, high, xhigh
```

If `:AISummaryConfig` is accidentally run from Visual mode, Neovim may prefix
the command with a range such as `:'<,'>`. The command accepts that range and
ignores it, because configuration changes are not selection-based.

Runtime changes are kept only in plugin memory. They do not write to your
Neovim config or Codex CLI config, and they disappear after restarting Neovim or
reloading the module.

## Configuration

```lua
require("ai-summary").setup({
  language = "zh-TW",
  provider = "codex",
  providers = {
    codex = {
      model = "gpt-5.5",
      reasoning_effort = "low",
    },
  },
  timeout_ms = 60000,
  window = {
    width = 0.72,
    height = 0.5,
    border = "rounded",
  },
})
```

For the built-in Codex provider, `model` and `reasoning_effort` are passed as
per-run `codex exec` arguments. The default command is equivalent to:

```bash
codex exec -m gpt-5.5 -c 'model_reasoning_effort="low"' -
```

This does not modify your global Codex CLI settings.

Built-in `model` and `reasoning_effort` mapping currently supports Codex only.
Other AI CLIs such as Claude Code, Gemini, opencode, or aider are not mapped by
the plugin yet because each CLI has different flags and execution rules. Use a
custom `cmd` for those providers until provider-specific adapters are planned.

To use a custom provider command:

```lua
require("ai-summary").setup({
  provider = "local-codex",
  providers = {
    ["local-codex"] = {
      cmd = { "/Users/you/bin/codex", "exec", "-" },
    },
  },
})
```

When `cmd` is configured, ai-summary.nvim runs it exactly as provided and does
not automatically append model or reasoning-effort arguments.
