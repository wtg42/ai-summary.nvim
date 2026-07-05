local M = {}

local function normalize_marks(start_mark, end_mark)
  local start_row = start_mark[2]
  local start_col = start_mark[3]
  local end_row = end_mark[2]
  local end_col = end_mark[3]

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  return start_row, start_col, end_row, end_col
end

function M.get_visual_text(bufnr, line1, line2)
  if not line1 or not line2 then
    return ""
  end

  bufnr = bufnr or 0

  local start_mark = vim.fn.getpos("'<")
  local end_mark = vim.fn.getpos("'>")
  local start_row, start_col, end_row, end_col = normalize_marks(start_mark, end_mark)

  if start_row == 0 or end_row == 0 then
    local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
    return table.concat(lines, "\n")
  end

  start_row = math.max(start_row, line1)
  end_row = math.min(end_row, line2)

  if start_row > end_row then
    return ""
  end

  local lines = vim.api.nvim_buf_get_text(
    bufnr,
    start_row - 1,
    math.max(start_col - 1, 0),
    end_row - 1,
    end_col,
    {}
  )

  return table.concat(lines, "\n")
end

return M
