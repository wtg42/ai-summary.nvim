local h = require("tests.helpers")

local context = {
  root = "/repo",
  cwd = "/repo/lua",
  relative_path = "lua/example.lua",
  filename = "/repo/lua/example.lua",
  filetype = "lua",
  extension = "lua",
  line1 = 10,
  line2 = 12,
  project_hints = { "stylua.toml" },
  language = "zh-TW",
}

local expected_summary = table.concat({
  "You are summarizing selected code from a repository.",
  "Answer language: zh-TW.",
  "Use Traditional Chinese when the answer language is zh-TW.",
  "",
  "Repository root: /repo",
  "Working directory: /repo/lua",
  "File: lua/example.lua",
  "Absolute file path: /repo/lua/example.lua",
  "Filetype/language: lua",
  "File extension: lua",
  "Selection range: lines 10-12",
  "Project hints: stylua.toml",
  "",
  "Instructions:",
  "- Prioritize the selected code.",
  "- Inspect external references in the repository only when needed to understand the selection.",
  "- Treat metadata as hints. If metadata conflicts with the selected code or repository files, trust the code and repository evidence.",
  "- Do not modify files. Do not run write operations. Explain only.",
  "- Keep the answer focused and concise.",
  "- Do not include an English translation.",
  "- Do not include token usage, diagnostics, CLI metadata, or process metadata.",
  "",
  "Return only Markdown using exactly these sections, in this order:",
  "## Summary",
  "## External References",
  "List only external repository files inspected to understand the selection.",
  "Use `relative/path:line` for references to a specific function, class, constant, setting, or behavior.",
  "Use `relative/path` without a line number only when the entire file is relevant as a whole.",
  "Write `None` if there are no external references.",
  "## Notes",
  "",
  "--- Selected Code ---",
  "return value",
}, "\n")

h.test("empty task preserves the exact summary prompt", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")

  h.eq(expected_summary, config.defaults.prompt("return value", context, ""))
end)

h.test("whitespace-only task preserves the exact summary prompt", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")

  h.eq(expected_summary, config.defaults.prompt("return value", context, "  \t "))
end)

h.test("custom task prompt is normalized, contextual, and read-only", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")
  local prompt =
    config.defaults.prompt("return value", context, "  Find possible race conditions  ")

  h.contains(prompt, "User task:\nFind possible race conditions")
  h.contains(prompt, "Repository root: /repo")
  h.contains(prompt, "File: lua/example.lua")
  h.contains(prompt, "Selection range: lines 10-12")
  h.contains(prompt, "--- Selected Code ---\nreturn value")
  h.contains(prompt, "Do not modify files")
  h.contains(prompt, "Return only Markdown")
  h.not_contains(prompt, "## Summary")
end)

h.test("Codex provider uses the default executable", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")
  config.setup()

  local provider = config.resolve_provider()

  h.eq("codex", provider.cmd[1])
  h.eq(
    { "exec", "-m", "gpt-5.6-terra", "-c", 'model_reasoning_effort="low"', "-" },
    vim.list_slice(provider.cmd, 2)
  )
end)

h.test("Codex executable preserves generated model and effort arguments", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")
  config.setup({
    providers = {
      codex = {
        executable = "codex-company",
        model = "company-model",
        reasoning_effort = "medium",
      },
    },
  })

  local provider = config.resolve_provider()

  h.eq({
    "codex-company",
    "exec",
    "-m",
    "company-model",
    "-c",
    'model_reasoning_effort="medium"',
    "-",
  }, provider.cmd)
end)

h.test("Codex executable can be changed for the current session", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")
  config.setup()

  h.truthy(config.set_codex_executable("  codex-company  "))
  h.eq(false, config.set_codex_executable("  "))

  local provider = config.resolve_provider()
  h.eq("codex-company", provider.cmd[1])
end)

h.test("custom cmd remains an exact override of the Codex executable", function()
  package.loaded["ai-summary.config"] = nil
  local config = require("ai-summary.config")
  local custom_cmd = { "wrapper", "--custom" }
  config.setup({
    providers = {
      codex = {
        executable = "codex-company",
        cmd = custom_cmd,
      },
    },
  })

  local provider = config.resolve_provider()

  h.eq(custom_cmd, provider.cmd)
end)

local function load_command(options)
  local selected_code = options.selection
  local state = {
    context_builds = 0,
    events = {},
    inputs = 0,
    notifications = {},
    output_opens = 0,
    provider_resolutions = 0,
    streams = {},
  }
  local input_callback
  local original_input = vim.ui.input
  local original_notify = vim.notify

  package.loaded["ai-summary"] = nil
  package.loaded["ai-summary.init"] = nil
  local config_module = {
    options = vim.tbl_extend("force", {
      language = "zh-TW",
      provider = "codex",
      providers = {
        codex = {
          executable = "codex",
          model = "gpt-5.6-terra",
          reasoning_effort = "low",
        },
      },
      prompt = function(code, prompt_context, task)
        state.prompt_args = { code, prompt_context, task }
        return "generated prompt"
      end,
      timeout_ms = 60000,
      window = {},
    }, options.config_options or {}),
    resolve_provider = function()
      state.provider_resolutions = state.provider_resolutions + 1
      return { cmd = { "provider" } }, "test"
    end,
    defaults = {
      providers = {
        codex = {
          executable = "codex",
          model = "gpt-5.6-terra",
          reasoning_effort = "low",
        },
      },
    },
    reasoning_effort_values = { "minimal", "low", "medium", "high", "xhigh" },
    reasoning_effort_list = function()
      return "minimal, low, medium, high, xhigh"
    end,
    setup = function() end,
  }
  config_module.set_codex_executable = function(executable)
    if not executable or vim.trim(executable) == "" then
      return false
    end

    config_module.options.providers.codex.executable = vim.trim(executable)
    return true
  end
  package.loaded["ai-summary.config"] = config_module
  state.config = config_module
  package.loaded["ai-summary.context"] = {
    build = function(_, line1, line2)
      state.context_builds = state.context_builds + 1
      return { cwd = "/repo", line1 = line1, line2 = line2 }
    end,
  }
  package.loaded["ai-summary.runner"] = {
    stream = function(args)
      table.insert(state.streams, args)
    end,
  }
  package.loaded["ai-summary.selection"] = {
    get_visual_text = function()
      return selected_code
    end,
  }
  package.loaded["ai-summary.ui"] = {
    open = function()
      table.insert(state.events, "output-open")
      state.output_opens = state.output_opens + 1
      return { append = function() end }
    end,
  }

  vim.ui.input = function(input_options, callback)
    state.inputs = state.inputs + 1
    state.input_options = input_options
    input_callback = callback
  end
  vim.notify = function(message, level)
    table.insert(state.notifications, { message = message, level = level })
  end

  local module = require("ai-summary")

  function state.submit(value)
    local output_count = state.output_opens
    input_callback(value)
    table.insert(state.events, "input-cleanup")

    if value ~= nil then
      vim.wait(1000, function()
        return state.output_opens > output_count
      end)
    end
  end

  function state.restore()
    vim.ui.input = original_input
    vim.notify = original_notify
  end

  function state.set_selection(value)
    selected_code = value
  end

  return module, state
end

h.test("valid selection opens an optional task input", function()
  local module, state = load_command({ selection = "local value = 1" })
  module.summarize_range(3, 3)

  h.eq(1, state.inputs)
  h.contains(state.input_options.prompt, "empty")
  h.eq(0, state.provider_resolutions)
  state.restore()
end)

h.test("invalid selection does not open task input", function()
  local module, state = load_command({ selection = "  \n" })
  module.summarize_range(3, 3)

  h.eq(0, state.inputs)
  h.eq(0, state.provider_resolutions)
  h.eq(1, #state.notifications)
  state.restore()
end)

h.test("cancelling task input creates no output or provider job", function()
  local module, state = load_command({ selection = "local value = 1" })
  module.summarize_range(3, 3)
  state.submit(nil)

  h.eq(0, state.context_builds)
  h.eq(0, state.output_opens)
  h.eq(0, state.provider_resolutions)
  h.eq(0, #state.streams)
  state.restore()
end)

h.test("output opens after the input UI finishes cleanup", function()
  local module, state = load_command({ selection = "local value = 1" })
  module.summarize_range(3, 3)
  state.submit("Explain this")

  h.eq({ "input-cleanup", "output-open" }, state.events)
  state.restore()
end)

h.test("empty submission sends nil task to the prompt callback", function()
  local module, state = load_command({ selection = "local value = 1" })
  module.summarize_range(3, 3)
  state.submit("   ")

  h.eq(nil, state.prompt_args[3])
  h.eq(1, #state.streams)
  h.eq("generated prompt", state.streams[1].stdin)
  state.restore()
end)

h.test("custom submission sends normalized task to the prompt callback", function()
  local module, state = load_command({ selection = "local value = 1" })
  module.summarize_range(3, 3)
  state.submit("  Find bugs  ")

  h.eq("Find bugs", state.prompt_args[3])
  h.eq(1, #state.streams)
  state.restore()
end)

h.test("existing two-argument prompt callback remains usable", function()
  local received
  local module, state = load_command({
    selection = "local value = 1",
    config_options = {
      prompt = function(code, prompt_context)
        received = { code, prompt_context }
        return "legacy prompt"
      end,
    },
  })
  module.summarize_range(3, 3)
  state.submit("Explain this")

  h.eq("local value = 1", received[1])
  h.eq("/repo", received[2].cwd)
  h.eq("legacy prompt", state.streams[1].stdin)
  state.restore()
end)

h.test("range command covers task input paths without adding a keymap", function()
  local normal_keymaps = vim.api.nvim_get_keymap("n")
  local visual_keymaps = vim.api.nvim_get_keymap("v")
  local module, state = load_command({ selection = "local value = 1" })

  module.setup()

  h.truthy(vim.api.nvim_get_commands({}).AISummary)
  h.eq(normal_keymaps, vim.api.nvim_get_keymap("n"))
  h.eq(visual_keymaps, vim.api.nvim_get_keymap("v"))

  vim.cmd("1,1AISummary")
  h.eq(1, state.inputs)
  state.submit("")
  h.eq(nil, state.prompt_args[3])
  h.eq(1, #state.streams)

  vim.cmd("1,1AISummary")
  state.submit("  Explain this  ")
  h.eq("Explain this", state.prompt_args[3])
  h.eq(2, #state.streams)

  vim.cmd("1,1AISummary")
  state.submit(nil)
  h.eq(2, state.output_opens)
  h.eq(2, #state.streams)

  state.set_selection("   ")
  vim.cmd("1,1AISummary")
  h.eq(3, state.inputs)
  h.eq(1, #state.notifications)

  vim.cmd("AISummaryConfig executable codex-company")
  h.eq("codex-company", state.config.options.providers.codex.executable)
  h.contains(state.notifications[2].message, "codex-company")

  vim.cmd("AISummaryConfig show")
  h.contains(state.notifications[3].message, "Executable: codex-company")

  vim.cmd("AISummaryConfig executable")
  h.eq("codex-company", state.config.options.providers.codex.executable)
  h.contains(state.notifications[4].message, "Missing executable value")

  state.config.options.providers.codex.cmd = { "custom-wrapper", "exec", "-" }
  vim.cmd("AISummaryConfig executable ignored-wrapper")
  h.eq("codex-company", state.config.options.providers.codex.executable)
  h.contains(state.notifications[5].message, "custom cmd")

  local completions = vim.fn.getcompletion("AISummaryConfig ex", "cmdline")
  h.truthy(vim.tbl_contains(completions, "executable"))

  state.restore()
end)
