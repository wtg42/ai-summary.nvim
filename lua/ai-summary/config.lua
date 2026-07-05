local M = {}

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
    "Use `relative/path:line` references when external files are relevant. Write `None` if there are no external references.",
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
      cmd = { "codex", "exec", "-" },
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

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), options or {})
end

return M
