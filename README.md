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
          executable = "codex",
          model = "gpt-5.6-terra",
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

The command opens a single-line task prompt:

```text
AI task (empty = summarize):
```

Press Enter without entering a task to use the default summary behavior, or
enter a focused task such as `Find possible race conditions`. Surrounding
whitespace is ignored. Press Esc to cancel without opening the output window or
starting the AI provider.

The selected code is sent to the configured provider with the task, file,
range, language, project-root, and lightweight project hints. Custom tasks are
read-only: the provider can analyze the code and suggest changes in its answer,
but the plugin does not allow it to modify repository files. Output streams
into a floating Markdown window. Press `q` in the output window to close it.

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

Change the Codex executable, model, or reasoning effort for the current Neovim session:

```vim
:AISummaryConfig executable codex-company
:AISummaryConfig model gpt-5.6-terra
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
      executable = "codex",
      model = "gpt-5.6-terra",
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

The optional `prompt` callback receives selected code, repository context, and
the normalized per-request task:

```lua
require("ai-summary").setup({
  prompt = function(code, context, task)
    if task then
      return task .. "\n\n" .. code
    end

    return "Summarize this code:\n\n" .. code
  end,
})
```

`task` is `nil` when the task input is empty. Existing callbacks that accept
only `code` and `context` remain compatible because Lua ignores extra function
arguments.

For the built-in Codex provider, `model` and `reasoning_effort` are passed as
per-run `codex exec` arguments. The default command is equivalent to:

```bash
codex exec -m gpt-5.6-terra -c 'model_reasoning_effort="low"' -
```

This does not modify your global Codex CLI settings.

Set `providers.codex.executable` to use a Codex-compatible wrapper while keeping
the generated `exec`, model, and reasoning-effort arguments:

```lua
require("ai-summary").setup({
  providers = {
    codex = {
      executable = "codex-company",
    },
  },
})
```

The executable is launched directly without a shell, so it may be a command on
`PATH` or an absolute path, but it must not contain shell syntax or additional
arguments. A wrapper must forward arguments and stdin to Codex. It must also
reserve stdout for the final answer; write diagnostics such as the active
`CODEX_HOME` to stderr instead, or they will appear in the summary output.

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
not automatically append executable, model, or reasoning-effort arguments.
