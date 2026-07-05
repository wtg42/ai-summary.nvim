## Context

The existing scaffold already separates configuration, selection extraction, CLI execution, and floating-window output. The MVP should preserve that simple shape while renaming the plugin direction from Codex-specific summary tooling to a vendor-neutral AI summary plugin.

The plugin runs inside Neovim, but the configured AI provider runs as an external CLI process. The external process cannot directly call Neovim APIs, so the plugin must provide enough selected-code and repository context for the provider to inspect the repo from the correct working directory.

## Goals / Non-Goals

**Goals:**
- Provide a command-first `:AISummary` flow for Visual selections.
- Keep the provider configurable while defaulting to Codex CLI.
- Send selected code plus focused metadata instead of the full buffer.
- Display streaming Markdown output in a native floating window.
- Stop long-running provider jobs after a configurable timeout.

**Non-Goals:**
- No default keymap in the MVP.
- No chat session, file editing, or AI-to-Neovim API bridge.
- No full language/framework detector.
- No LazyVim-specific runtime dependency or UI integration.

## Decisions

- Use `ai-summary.nvim`, `require("ai-summary")`, and `:AISummary` as vendor-neutral names. Alternative considered: keep Codex-specific naming. Vendor-neutral naming avoids a later breaking rename when Claude Code, Opencode, or another provider is added.
- Keep the MVP command-based and do not install a default keymap. Alternative considered: default `<leader>` mapping. A command-first entry avoids LazyVim keymap conflicts and lets users add their preferred mapping.
- Model providers as named command configurations with Codex as the default. Alternative considered: a single `cmd` option only. Provider naming keeps the first version simple while leaving room for provider-specific commands later.
- Build a prompt envelope containing selected code, cwd/root, file path, filetype, extension, line range, project hints, and response-format instructions. Alternative considered: send the whole buffer. Selected-code-first prompts reduce token use and keep the answer focused.
- Run the provider from the detected repository root when possible. Alternative considered: always use `vim.fn.getcwd()`. Root-aware cwd makes provider-side `rg` and file reads more likely to find external references.
- Use native Neovim floating Markdown output for the MVP. Alternative considered: Telescope, Trouble, or LazyVim UI integrations. Native UI works for standard Neovim and LazyVim without extra dependencies.
- Add timeout handling in the runner with a 60-second default. Alternative considered: rely on the provider to finish. Plugin-owned timeout gives users a predictable escape hatch for slow or stuck requests.

## Risks / Trade-offs

- Root detection may choose the wrong directory in unusual nested repos -> allow future explicit `root_dir` configuration if needed.
- Provider CLIs differ in stdin and argument conventions -> keep the MVP provider interface minimal and evolve it only when adding a second provider.
- Filetype and framework hints can be wrong -> instruct the provider to treat metadata as hints and prioritize selected code plus repository evidence.
- Markdown output is easy to read but only loosely structured -> use stable section headings and `relative/path:line` references so later parsing remains possible.
