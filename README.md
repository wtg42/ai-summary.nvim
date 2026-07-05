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
    cmd = "AISummary",
    opts = {
      provider = "codex",
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

## Configuration

```lua
require("ai-summary").setup({
  language = "zh-TW",
  provider = "codex",
  providers = {
    codex = {
      cmd = { "codex", "exec", "-" },
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
