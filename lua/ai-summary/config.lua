local M = {}

local allowed_reasoning_efforts = {
  minimal = true,
  low = true,
  medium = true,
  high = true,
  xhigh = true,
}

local reasoning_effort_values = { "minimal", "low", "medium", "high", "xhigh" }
local interactive_prompt_max_bytes = 96 * 1024
local interactive_context_max_bytes = 40 * 1024
local interactive_task_max_bytes = 8 * 1024

local function limit_interactive_context(value, max_bytes)
  value = tostring(value or "")

  if #value <= max_bytes then
    return value
  end

  local marker = "\n\n[Context truncated for interactive startup.]"
  local cutoff = max_bytes - #marker
  local end_index = cutoff
  local lead_index = cutoff

  while lead_index > 0 do
    local byte = value:byte(lead_index)

    if not byte or byte < 0x80 or byte > 0xBF then
      break
    end

    lead_index = lead_index - 1
  end

  local lead = value:byte(lead_index)
  local sequence_length = 1

  if lead and lead >= 0xC2 and lead <= 0xDF then
    sequence_length = 2
  elseif lead and lead >= 0xE0 and lead <= 0xEF then
    sequence_length = 3
  elseif lead and lead >= 0xF0 and lead <= 0xF4 then
    sequence_length = 4
  end

  if sequence_length > 1 then
    if lead_index + sequence_length - 1 > cutoff then
      end_index = lead_index - 1
    else
      end_index = cutoff
    end
  end

  return value:sub(1, end_index) .. marker
end

local function format_project_hints(hints)
  if not hints or #hints == 0 then
    return "none"
  end

  return table.concat(hints, ", ")
end

local function default_summary_prompt(code, context)
  local language = context.language or "zh-TW"

  return table.concat({
    "You are summarizing selected code from a repository.",
    "Answer language: " .. language .. ".",
    "Use Traditional Chinese when the answer language is zh-TW.",
    "",
    "Repository root: " .. (context.root or "unknown"),
    "Working directory: " .. (context.cwd or "unknown"),
    "File: " .. (context.relative_path or context.filename or "unknown"),
    "Absolute file path: " .. (context.filename or "unknown"),
    "Filetype/language: " .. (context.filetype or "unknown"),
    "File extension: " .. (context.extension or "unknown"),
    "Selection range: lines " .. tostring(context.line1 or "unknown") .. "-" .. tostring(
      context.line2 or "unknown"
    ),
    "Project hints: " .. format_project_hints(context.project_hints),
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
    code,
  }, "\n")
end

local function custom_task_prompt(code, context, task)
  local language = context.language or "zh-TW"

  return table.concat({
    "You are performing a read-only task on selected code from a repository.",
    "Answer language: " .. language .. ".",
    "Use Traditional Chinese when the answer language is zh-TW.",
    "",
    "Repository root: " .. (context.root or "unknown"),
    "Working directory: " .. (context.cwd or "unknown"),
    "File: " .. (context.relative_path or context.filename or "unknown"),
    "Absolute file path: " .. (context.filename or "unknown"),
    "Filetype/language: " .. (context.filetype or "unknown"),
    "File extension: " .. (context.extension or "unknown"),
    "Selection range: lines " .. tostring(context.line1 or "unknown") .. "-" .. tostring(
      context.line2 or "unknown"
    ),
    "Project hints: " .. format_project_hints(context.project_hints),
    "",
    "User task:",
    task,
    "",
    "Instructions:",
    "- Perform the user task with priority on the selected code.",
    "- Inspect external references in the repository only when needed to complete the task.",
    "- Treat metadata as hints. If metadata conflicts with the selected code or repository files, trust the code and repository evidence.",
    "- Do not modify files. Do not run write operations. Respond with analysis or suggested code only.",
    "- Keep the answer focused and concise.",
    "- Do not include an English translation.",
    "- Do not include token usage, diagnostics, CLI metadata, or process metadata.",
    "- Return only Markdown in a structure appropriate for the user task.",
    "",
    "--- Selected Code ---",
    code,
  }, "\n")
end

local function default_prompt(code, context, task)
  local normalized_task = vim.trim(task or "")

  if normalized_task == "" then
    return default_summary_prompt(code, context)
  end

  return custom_task_prompt(code, context, normalized_task)
end

function M.build_interactive_prompt(code, context, task, answer)
  local language = context.language or "zh-TW"
  local task_description = limit_interactive_context(
    task or "Use the default summary request.",
    interactive_task_max_bytes
  )
  local limited_code = limit_interactive_context(code, interactive_context_max_bytes)
  local limited_answer = limit_interactive_context(answer, interactive_context_max_bytes)

  local prompt = table.concat({
    "You are now continuing from an ai-summary.nvim answer in an interactive Codex session.",
    "Answer language: " .. language .. ".",
    "Use Traditional Chinese when the answer language is zh-TW.",
    "",
    "Repository root: " .. (context.root or "unknown"),
    "Working directory: " .. (context.cwd or "unknown"),
    "File: " .. (context.relative_path or context.filename or "unknown"),
    "Absolute file path: " .. (context.filename or "unknown"),
    "Filetype/language: " .. (context.filetype or "unknown"),
    "Selection range: lines " .. tostring(context.line1 or "unknown") .. "-" .. tostring(
      context.line2 or "unknown"
    ),
    "",
    "Initial user task:",
    task_description,
    "",
    "The first answer from ai-summary.nvim:",
    limited_answer,
    "",
    "Instructions:",
    "- Continue the conversation with the user and answer follow-up questions directly.",
    "- Inspect the repository from the repository root when needed.",
    "- Only modify files when the user explicitly asks for a modification.",
    "- Keep requested changes focused and show changed files and validation in your answer.",
    "- The selected code below comes from the editor and may include unsaved changes; verify it against repository files before editing.",
    "",
    "--- Selected Code ---",
    limited_code,
  }, "\n")

  return limit_interactive_context(prompt, interactive_prompt_max_bytes)
end

M.defaults = {
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
  prompt = default_prompt,
}

M.options = vim.deepcopy(M.defaults)

M.reasoning_effort_values = vim.deepcopy(reasoning_effort_values)

function M.is_valid_reasoning_effort(value)
  return allowed_reasoning_efforts[value] == true
end

function M.reasoning_effort_list()
  return table.concat(reasoning_effort_values, ", ")
end

local function build_codex_cmd(provider)
  local model = provider.model or M.defaults.providers.codex.model
  local effort = provider.reasoning_effort or M.defaults.providers.codex.reasoning_effort

  return {
    provider.executable or M.defaults.providers.codex.executable,
    "exec",
    "-m",
    model,
    "-c",
    ('model_reasoning_effort="%s"'):format(effort),
    "-",
  }
end

local function build_codex_interactive_cmd(provider, cwd, prompt)
  local model = provider.model or M.defaults.providers.codex.model
  local effort = provider.reasoning_effort or M.defaults.providers.codex.reasoning_effort

  return {
    provider.executable or M.defaults.providers.codex.executable,
    "-C",
    cwd,
    "-m",
    model,
    "-c",
    ('model_reasoning_effort="%s"'):format(effort),
    "-s",
    "workspace-write",
    "-a",
    "on-request",
    prompt,
  }
end

local function normalize_codex_provider(options)
  local provider = options.providers and options.providers.codex

  if not provider then
    return
  end

  if provider.reasoning_effort and not M.is_valid_reasoning_effort(provider.reasoning_effort) then
    vim.notify(
      ("Invalid Codex reasoning effort '%s'; falling back to '%s'. Allowed values: %s"):format(
        tostring(provider.reasoning_effort),
        M.defaults.providers.codex.reasoning_effort,
        M.reasoning_effort_list()
      ),
      vim.log.levels.WARN,
      { title = "ai-summary.nvim" }
    )
    provider.reasoning_effort = M.defaults.providers.codex.reasoning_effort
  end
end

function M.resolve_provider(opts)
  opts = opts or M.options

  local provider_name = opts.provider or "codex"
  local provider = opts.providers and opts.providers[provider_name]

  if not provider then
    return nil, provider_name
  end

  if type(provider.cmd) == "table" and #provider.cmd > 0 then
    return provider, provider_name
  end

  if provider_name == "codex" then
    return vim.tbl_extend("force", provider, {
      cmd = build_codex_cmd(provider),
    }),
      provider_name
  end

  return nil, provider_name
end

function M.resolve_interactive_command(opts, cwd, prompt)
  opts = opts or M.options

  local provider_name = opts.provider or "codex"
  local provider = opts.providers and opts.providers[provider_name]

  if provider_name ~= "codex" or not provider or (type(provider.cmd) == "table" and #provider.cmd > 0) then
    return nil, provider_name
  end

  if type(cwd) ~= "string" or vim.trim(cwd) == "" or type(prompt) ~= "string" then
    return nil, provider_name
  end

  return build_codex_interactive_cmd(provider, cwd, prompt), provider_name
end

function M.set_codex_model(model)
  if not model or model == "" then
    return false
  end

  M.options.providers.codex.model = model

  return true
end

function M.set_codex_executable(executable)
  if type(executable) ~= "string" or vim.trim(executable) == "" then
    return false
  end

  M.options.providers.codex.executable = vim.trim(executable)

  return true
end

function M.set_codex_reasoning_effort(effort)
  if not M.is_valid_reasoning_effort(effort) then
    return false
  end

  M.options.providers.codex.reasoning_effort = effort

  return true
end

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), options or {})
  normalize_codex_provider(M.options)
end

return M
