local M = {}

local Output = {}
Output.__index = Output

local function resolve_size(value, total)
  if value > 0 and value < 1 then
    return math.floor(total * value)
  end

  return math.floor(value)
end

function Output:append(text)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    return
  end

  local lines = vim.split(text, "\n", { plain = true })
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  local last_line = vim.api.nvim_buf_get_lines(self.bufnr, line_count - 1, line_count, false)[1] or ""

  lines[1] = last_line .. lines[1]
  vim.api.nvim_buf_set_lines(self.bufnr, line_count - 1, line_count, false, lines)

  if vim.api.nvim_win_is_valid(self.winid) then
    local new_line_count = vim.api.nvim_buf_line_count(self.bufnr)
    vim.api.nvim_win_set_cursor(self.winid, { new_line_count, 0 })
  end
end

function Output:close()
  if vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, true)
  end
end

function M.open(options)
  options = options or {}

  local width = resolve_size(options.width or 0.72, vim.o.columns)
  local height = resolve_size(options.height or 0.5, vim.o.lines)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "markdown"

  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = options.border or "rounded",
    title = " AI Summary ",
    title_pos = "center",
  })

  vim.wo[winid].wrap = true
  vim.wo[winid].cursorline = false

  local output = setmetatable({
    bufnr = bufnr,
    winid = winid,
  }, Output)

  vim.keymap.set("n", "q", function()
    output:close()
  end, { buffer = bufnr, silent = true, desc = "Close summary" })

  return output
end

function M.open_terminal(options, cmd, cwd, on_exit)
  options = options or {}

  local width = resolve_size(options.width or 0.72, vim.o.columns)
  local height = resolve_size(options.height or 0.5, vim.o.lines)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "wipe"

  local winid = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = options.border or "rounded",
    title = " Codex Interactive ",
    title_pos = "center",
  })

  local function close_window()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end
  end

  vim.keymap.set({ "n", "t" }, "<C-q>", close_window, {
    buffer = bufnr,
    silent = true,
    desc = "Close Codex interactive session",
  })

  local started, job_id = pcall(vim.fn.termopen, cmd, {
    cwd = cwd,
    on_exit = function(_, code)
      vim.schedule(function()
        close_window()

        if on_exit then
          on_exit(code)
        end
      end)
    end,
  })

  if not started or type(job_id) ~= "number" or job_id <= 0 then
    close_window()
    return nil, job_id
  end

  return job_id
end

return M
