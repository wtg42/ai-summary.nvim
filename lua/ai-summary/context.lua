local M = {}

local uv = vim.uv or vim.loop

local function join_path(...)
  return table.concat(vim.tbl_filter(function(part)
    return part and part ~= ""
  end, { ... }), "/"):gsub("//+", "/")
end

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function dirname(path)
  if vim.fs and vim.fs.dirname then
    return vim.fs.dirname(path)
  end

  return vim.fn.fnamemodify(path, ":h")
end

local function detect_git_root(start_dir)
  if vim.fs and vim.fs.find then
    local git_dir = vim.fs.find(".git", { path = start_dir, upward = true })[1]

    if git_dir then
      return dirname(git_dir)
    end
  end

  local output = vim.fn.systemlist({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })

  if vim.v.shell_error == 0 and output[1] and output[1] ~= "" then
    return output[1]
  end

  return nil
end

local function relative_path(path, root)
  if not path or path == "" or not root or root == "" then
    return path
  end

  local absolute = vim.fn.fnamemodify(path, ":p")
  local normalized_root = vim.fn.fnamemodify(root, ":p"):gsub("/$", "") .. "/"

  if absolute:sub(1, #normalized_root) == normalized_root then
    return absolute:sub(#normalized_root + 1)
  end

  return path
end

local function detect_project_hints(root)
  if not root or root == "" then
    return {}
  end

  local hints = {}

  if path_exists(join_path(root, "composer.json")) then
    table.insert(hints, "PHP project (composer.json)")
  end

  if path_exists(join_path(root, "artisan")) then
    table.insert(hints, "Laravel project (artisan)")
  end

  if path_exists(join_path(root, "package.json")) then
    table.insert(hints, "JavaScript or TypeScript project (package.json)")
  end

  if path_exists(join_path(root, "go.mod")) then
    table.insert(hints, "Go project (go.mod)")
  end

  if path_exists(join_path(root, "Cargo.toml")) then
    table.insert(hints, "Rust project (Cargo.toml)")
  end

  return hints
end

function M.detect_root(bufnr)
  bufnr = bufnr or 0

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.fn.getcwd()
  local start_dir = cwd

  if filename and filename ~= "" then
    start_dir = vim.fn.fnamemodify(filename, ":p:h")
  end

  return detect_git_root(start_dir) or cwd
end

function M.build(bufnr, line1, line2)
  bufnr = bufnr or 0

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local root = M.detect_root(bufnr)

  return {
    cwd = vim.fn.getcwd(),
    root = root,
    filename = filename ~= "" and filename or nil,
    relative_path = relative_path(filename, root),
    filetype = vim.bo[bufnr].filetype ~= "" and vim.bo[bufnr].filetype or nil,
    extension = filename ~= "" and vim.fn.fnamemodify(filename, ":e") or nil,
    line1 = line1,
    line2 = line2,
    project_hints = detect_project_hints(root),
  }
end

return M
