local M = {}

local total = 0
local failed = 0

local function format(value)
  return vim.inspect(value)
end

function M.eq(expected, actual, message)
  if not vim.deep_equal(expected, actual) then
    error(
      (message or "values differ")
        .. "\nexpected: "
        .. format(expected)
        .. "\nactual: "
        .. format(actual),
      2
    )
  end
end

function M.truthy(value, message)
  if not value then
    error(message or "expected a truthy value", 2)
  end
end

function M.contains(value, expected, message)
  if not value:find(expected, 1, true) then
    error(
      (message or "substring not found")
        .. "\nexpected substring: "
        .. expected
        .. "\nactual: "
        .. value,
      2
    )
  end
end

function M.not_contains(value, unexpected, message)
  if value:find(unexpected, 1, true) then
    error(
      (message or "unexpected substring found")
        .. "\nunexpected substring: "
        .. unexpected
        .. "\nactual: "
        .. value,
      2
    )
  end
end

function M.test(name, callback)
  total = total + 1
  local ok, err = xpcall(callback, debug.traceback)

  if ok then
    print("ok " .. total .. " - " .. name)
    return
  end

  failed = failed + 1
  print("not ok " .. total .. " - " .. name)
  print(err)
end

function M.finish()
  print(("%d tests, %d failures"):format(total, failed))

  if failed > 0 then
    vim.cmd("cquit 1")
  end
end

return M
