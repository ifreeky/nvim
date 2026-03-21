local M = {}

local function path_exists(path)
  return path ~= nil and (vim.uv or vim.loop).fs_stat(path) ~= nil
end

local function has_marker(dir, marker)
  return path_exists(vim.fs.joinpath(dir, marker))
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local dir = vim.fs.dirname(vim.fs.normalize(path))
  local maven_root
  local gradle_root
  local git_root

  while dir and dir ~= "" do
    if has_marker(dir, "pom.xml") or has_marker(dir, ".mvn") then
      maven_root = dir
    end

    if
      has_marker(dir, "settings.gradle")
      or has_marker(dir, "settings.gradle.kts")
      or has_marker(dir, "build.gradle")
      or has_marker(dir, "build.gradle.kts")
      or has_marker(dir, ".gradle")
    then
      gradle_root = dir
    end

    if has_marker(dir, ".git") then
      git_root = dir
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return maven_root or gradle_root or git_root
end

function M.root_dir(bufnr, on_dir)
  on_dir(M.find_root(vim.api.nvim_buf_get_name(bufnr)))
end

function M.jdtls_cmd()
  local cmd = vim.fn.exepath("jdtls")
  return { cmd ~= "" and cmd or "jdtls" }
end

return M
