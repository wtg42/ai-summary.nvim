## 1. Regression Tests

- [x] 1.1 Add focused Lua test support for loading plugin modules with mocked Neovim APIs and provider/UI collaborators.
- [x] 1.2 Add failing tests proving empty and whitespace-only submissions preserve the existing summary prompt exactly, while a normalized custom task produces the task-specific read-only prompt.
- [x] 1.3 Add failing command-flow tests proving valid selections open task input, invalid selections do not, cancellation creates no output or provider job, and custom prompt callbacks receive the optional third argument.

## 2. Prompt Construction

- [x] 2.1 Extend the built-in prompt callback with an optional task argument without changing the generated default-summary prompt.
- [x] 2.2 Build the custom-task prompt with normalized task text, selected code, language and repository metadata, Markdown response guidance, and mandatory read-only instructions without summary-specific headings.

## 3. Command Integration

- [x] 3.1 Request an optional task through `vim.ui.input` only after the selected code passes existing validation.
- [x] 3.2 Distinguish cancellation from submitted empty input and defer context building, output-window creation, provider resolution, and provider startup until a value is submitted.
- [x] 3.3 Pass `nil` or the normalized custom task to the configured prompt callback and keep streaming, failure, timeout, and last-summary behavior intact.

## 4. Documentation and Verification

- [x] 4.1 Document the input prompt, empty-submit default, custom read-only tasks, cancellation behavior, and optional third prompt-callback argument in the README.
- [x] 4.2 Run the focused automated tests and format the changed Lua files with the repository's Stylua configuration.
- [x] 4.3 Manually verify in headless or interactive Neovim that `:AISummary` covers default summary, custom task, cancellation, and invalid-selection paths without adding a default keymap or dependency.

## 5. Input UI Focus Regression

- [x] 5.1 Add a regression test proving output creation occurs after the input UI callback finishes restoring editor state.
- [x] 5.2 Schedule submitted requests on the next event-loop turn so the output window retains focus and its `q` mapping works with third-party input UIs.
- [x] 5.3 Format and rerun the focused tests, then validate the updated OpenSpec change.
