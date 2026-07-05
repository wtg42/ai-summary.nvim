local M = {}

local uv = vim.uv or vim.loop

local function normalize_chunk(data)
  if type(data) == "string" then
    return data
  end

  if type(data) ~= "table" then
    return ""
  end

  return table.concat(data, "\n")
end

local function close_timer(timer)
  if not timer then
    return
  end

  timer:stop()
  timer:close()
end

function M.stream(args)
  vim.validate({
    cmd = { args.cmd, "table" },
    stdin = { args.stdin, "string" },
    cwd = { args.cwd, "string", true },
    timeout_ms = { args.timeout_ms, "number", true },
    on_stdout = { args.on_stdout, "function", true },
    on_stderr = { args.on_stderr, "function", true },
    on_exit = { args.on_exit, "function", true },
    on_start_error = { args.on_start_error, "function", true },
    on_timeout = { args.on_timeout, "function", true },
  })

  local timer
  local timed_out = false
  local job_id
  local job_options = {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      local chunk = normalize_chunk(data)
      if chunk ~= "" and args.on_stdout then
        vim.schedule(function()
          args.on_stdout(chunk)
        end)
      end
    end,
    on_stderr = function(_, data)
      local chunk = normalize_chunk(data)
      if chunk ~= "" and args.on_stderr then
        vim.schedule(function()
          args.on_stderr(chunk)
        end)
      end
    end,
    on_exit = function(_, code)
      close_timer(timer)

      if args.on_exit then
        vim.schedule(function()
          args.on_exit(code, timed_out)
        end)
      end
    end,
  }

  if args.cwd and args.cwd ~= "" then
    job_options.cwd = args.cwd
  end

  local started, result = pcall(vim.fn.jobstart, args.cmd, job_options)

  if not started then
    if args.on_start_error then
      vim.schedule(function()
        args.on_start_error(result)
      end)
    else
      vim.notify("Failed to start provider command", vim.log.levels.ERROR, { title = "ai-summary.nvim" })
    end
    return nil
  end

  job_id = result

  if job_id <= 0 then
    if args.on_start_error then
      vim.schedule(function()
        args.on_start_error()
      end)
    else
      vim.notify("Failed to start provider command", vim.log.levels.ERROR, { title = "ai-summary.nvim" })
    end
    return nil
  end

  if args.timeout_ms and args.timeout_ms > 0 then
    timer = uv.new_timer()
    timer:start(args.timeout_ms, 0, function()
      timed_out = true
      vim.schedule(function()
        if args.on_timeout then
          args.on_timeout(args.timeout_ms)
        end

        if job_id and job_id > 0 then
          vim.fn.jobstop(job_id)
        end
      end)
    end)
  end

  vim.fn.chansend(job_id, args.stdin)
  vim.fn.chanclose(job_id, "stdin")

  return job_id
end

return M
