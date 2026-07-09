local M = {}

local allowed_reasoning_efforts = {
  minimal = true,
  low = true,
  medium = true,
  high = true,
  xhigh = true,
}

local reasoning_effort_values = { "minimal", "low", "medium", "high", "xhigh" }

local function format_project_hints(hints)
  if not hints or #hints == 0 then
    return "none"
  end

  return table.concat(hints, ", ")
end

local function default_prompt(code, context)
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
    "Selection range: lines " .. tostring(context.line1 or "unknown") .. "-" .. tostring(context.line2 or "unknown"),
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

M.defaults = {
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
    "codex",
    "exec",
    "-m",
    model,
    "-c",
    ('model_reasoning_effort="%s"'):format(effort),
    "-",
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
    }), provider_name
  end

  return nil, provider_name
end

function M.set_codex_model(model)
  if not model or model == "" then
    return false
  end

  M.options.providers.codex.model = model

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
