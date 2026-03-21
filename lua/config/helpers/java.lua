local M = {}

local function path_exists(path)
  return path ~= nil and (vim.uv or vim.loop).fs_stat(path) ~= nil
end

local function has_marker(dir, marker)
  return path_exists(vim.fs.joinpath(dir, marker))
end

local function build_root(dir)
  if has_marker(dir, "pom.xml") or has_marker(dir, ".mvn") then
    return dir
  end

  if
    has_marker(dir, "settings.gradle")
    or has_marker(dir, "settings.gradle.kts")
    or has_marker(dir, "build.gradle")
    or has_marker(dir, "build.gradle.kts")
    or has_marker(dir, ".gradle")
  then
    return dir
  end
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local dir = vim.fs.dirname(vim.fs.normalize(path))
  local git_root

  while dir and dir ~= "" do
    local root = build_root(dir)
    if root then
      return root
    end

    if not git_root and has_marker(dir, ".git") then
      git_root = dir
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return git_root
end

function M.root_dir(bufnr, on_dir)
  on_dir(M.find_root(vim.api.nvim_buf_get_name(bufnr)))
end

return M
