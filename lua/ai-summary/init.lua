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

local function notify_config(message, level)
  notify(message, level)
end

local function command_to_string(cmd)
  return table.concat(vim.tbl_map(tostring, cmd), " ")
end

local function starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function filter_completion(values, prefix)
  local matches = {}

  for _, value in ipairs(values) do
    if starts_with(value, prefix or "") then
      table.insert(matches, value)
    end
  end

  return matches
end

local function config_usage()
  return table.concat({
    "Usage:",
    "  :AISummaryConfig show",
    "  :AISummaryConfig model gpt-5.5",
    "  :AISummaryConfig effort low",
    "  :AISummaryConfig effort medium",
    "",
    "Allowed effort values: " .. config.reasoning_effort_list(),
  }, "\n")
end

local function notify_config_usage(message)
  notify_config(message .. "\n\n" .. config_usage(), vim.log.levels.WARN)
end

local function active_provider()
  return config.options.provider or "codex"
end

local function show_config()
  local provider_name = active_provider()
  local provider = config.options.providers and config.options.providers[provider_name]

  if provider_name ~= "codex" then
    notify_config(
      ("Active provider: %s\nModel and reasoning effort options currently apply to Codex only."):format(provider_name)
    )
    return
  end

  provider = provider or {}

  local lines = {
    "Active provider: codex",
    "Model: " .. tostring(provider.model or config.defaults.providers.codex.model),
    "Reasoning effort: " .. tostring(provider.reasoning_effort or config.defaults.providers.codex.reasoning_effort),
  }

  if type(provider.cmd) == "table" and #provider.cmd > 0 then
    table.insert(lines, "Custom cmd is configured; model and reasoning effort are not applied automatically.")
  end

  notify_config(table.concat(lines, "\n"))
end

local function set_model(model)
  if not model or model == "" then
    notify_config_usage("Missing model value.")
    return
  end

  config.set_codex_model(model)
  notify_config(("Codex model set to %s for this Neovim session."):format(model))
end

local function set_effort(effort)
  if not effort or effort == "" then
    notify_config_usage("Missing reasoning effort value.")
    return
  end

  if not config.set_codex_reasoning_effort(effort) then
    notify_config_usage(("Invalid reasoning effort: %s"):format(effort))
    return
  end

  notify_config(("Codex reasoning effort set to %s for this Neovim session."):format(effort))
end

local function handle_config_command(command)
  local subcommand = command.fargs[1] or "show"

  if subcommand == "show" then
    show_config()
    return
  end

  if subcommand == "model" then
    set_model(command.fargs[2])
    return
  end

  if subcommand == "effort" then
    set_effort(command.fargs[2])
    return
  end

  notify_config_usage(("Unknown AISummaryConfig command: %s"):format(subcommand))
end

local function complete_config(arg_lead, cmd_line)
  local parts = vim.split(cmd_line, "%s+", { trimempty = true })
  local subcommand = parts[2]

  if #parts <= 1 or (#parts == 2 and not cmd_line:match("%s$")) then
    return filter_completion({ "show", "model", "effort" }, arg_lead)
  end

  if subcommand == "effort" then
    return filter_completion(config.reasoning_effort_values, arg_lead)
  end

  return {}
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
  local provider, provider_name = config.resolve_provider(opts)

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

  vim.api.nvim_create_user_command("AISummaryConfig", handle_config_command, {
    nargs = "*",
    range = true,
    complete = complete_config,
  })
end

return M
