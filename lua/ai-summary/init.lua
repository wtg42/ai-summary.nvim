local config = require("ai-summary.config")
local context = require("ai-summary.context")
local runner = require("ai-summary.runner")
local selection = require("ai-summary.selection")
local ui = require("ai-summary.ui")

local M = {}

local last_summary = nil

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "ai-summary.nvim" })
end

local function command_to_string(cmd)
  return table.concat(vim.tbl_map(tostring, cmd), " ")
end

local function resolve_provider(opts)
  local provider_name = opts.provider or "codex"
  local provider = opts.providers and opts.providers[provider_name]

  if not provider or type(provider.cmd) ~= "table" or #provider.cmd == 0 then
    return nil, provider_name
  end

  return provider, provider_name
end

function M.summarize_range(line1, line2)
  if not line1 or not line2 then
    notify("No code selected", vim.log.levels.WARN)
    return
  end

  local code = selection.get_visual_text(0, line1, line2)

  if not code:match("%S") then
    notify("No code selected", vim.log.levels.WARN)
    return
  end

  local opts = config.options
  local provider, provider_name = resolve_provider(opts)

  if not provider then
    notify(("Provider '%s' is not configured"):format(provider_name), vim.log.levels.ERROR)
    return
  end

  local summary_context = context.build(0, line1, line2)
  summary_context.language = opts.language
  local prompt = opts.prompt(code, summary_context)
  local output = ui.open(opts.window)
  local stdout_chunks = {}
  local stderr_chunks = {}

  output:append("Running AI summary...\n\n")

  runner.stream({
    cmd = provider.cmd,
    cwd = summary_context.root or summary_context.cwd,
    stdin = prompt,
    timeout_ms = opts.timeout_ms,
    on_stdout = function(chunk)
      table.insert(stdout_chunks, chunk)
      output:append(chunk)
    end,
    on_stderr = function(chunk)
      table.insert(stderr_chunks, chunk)
    end,
    on_start_error = function()
      output:append(("Failed to start provider command: %s"):format(command_to_string(provider.cmd)))
    end,
    on_timeout = function(timeout_ms)
      output:append(("\n\nTimed out after %ds"):format(math.floor(timeout_ms / 1000)))
    end,
    on_exit = function(code, timed_out)
      if timed_out then
        return
      end

      local stdout = table.concat(stdout_chunks)

      if code == 0 and stdout:match("%S") then
        last_summary = stdout
      end

      if code ~= 0 then
        local stderr = table.concat(stderr_chunks)

        if stderr:match("%S") then
          output:append(("\n\nProvider error output:\n\n%s"):format(stderr))
        end

        output:append(("\n\nProcess exited with code %d"):format(code))
      end
    end,
  })
end

function M.show_last_summary()
  if not last_summary or not last_summary:match("%S") then
    notify("No previous AI summary", vim.log.levels.WARN)
    return
  end

  local output = ui.open(config.options.window)
  output:append(last_summary)
end

function M.setup(options)
  config.setup(options)

  vim.api.nvim_create_user_command("AISummary", function(command)
    local subcommand = vim.trim(command.args or "")

    if subcommand == "last" then
      M.show_last_summary()
      return
    end

    if subcommand ~= "" then
      notify(("Unknown AISummary command: %s"):format(subcommand), vim.log.levels.WARN)
      return
    end

    if command.range == 0 then
      M.summarize_range(nil, nil)
      return
    end

    M.summarize_range(command.line1, command.line2)
  end, {
    nargs = "?",
    range = true,
    complete = function()
      return { "last" }
    end,
  })
end

return M
