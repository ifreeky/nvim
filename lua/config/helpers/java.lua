local M = {}

local function path_exists(path)
  return path ~= nil and (vim.uv or vim.loop).fs_stat(path) ~= nil
end

local function has_marker(dir, marker)
  return path_exists(vim.fs.joinpath(dir, marker))
end

local function eligible_root(dir)
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

  if has_marker(dir, ".git") then
    return dir
  end
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local dir = vim.fs.dirname(vim.fs.normalize(path))

  while dir and dir ~= "" do
    local root = eligible_root(dir)
    if root then
      return root
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

function M.root_dir(bufnr, on_dir)
  on_dir(M.find_root(vim.api.nvim_buf_get_name(bufnr)))
end

function M.jdtls_cmd()
  local cmd = vim.fn.exepath("jdtls")
  return { cmd ~= "" and cmd or "jdtls" }
end

return M
