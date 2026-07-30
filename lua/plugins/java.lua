-- ── Utility helpers ──────────────────────────────────────────────────────────

local function directory_exists(path)
  return path and vim.fn.isdirectory(path) == 1
end

local function file_exists(path)
  return path and vim.fn.filereadable(path) == 1
end

local function read_file(path)
  if not file_exists(path) then
    return nil
  end

  local lines = vim.fn.readfile(path)
  return #lines > 0 and table.concat(lines, "\n") or ""
end

local function parent_dir(path)
  local parent = vim.fs.dirname(path)
  return parent ~= path and parent or nil
end

local function normalize_dir(path)
  if not path or path == "" then
    return nil
  end

  local normalized = vim.fs.normalize(path)
  if vim.fn.isdirectory(normalized) == 1 then
    return normalized
  end

  return vim.fs.dirname(normalized)
end

-- ── Java Home / Runtime detection ───────────────────────────────────────────

local function resolve_brew_java_home(formula)
  if vim.fn.executable("brew") == 0 then
    return nil
  end

  local output = vim.fn.system({ "brew", "--prefix", formula })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local prefix = vim.trim(output)
  local home = prefix ~= "" and (prefix .. "/libexec/openjdk.jdk/Contents/Home") or nil
  return directory_exists(home) and home or nil
end

local function resolve_java_home(version)
  if tonumber(version) == 21 then
    local brew_home = resolve_brew_java_home("openjdk@21")
    if brew_home then
      return brew_home
    end
  end

  local output = vim.fn.system({ "/usr/libexec/java_home", "-v", tostring(version) })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local path = vim.trim(output)
  return directory_exists(path) and path or nil
end

local function configured_runtimes()
  local runtimes = {}
  local java21_home = resolve_java_home(21)
  local java17_home = resolve_java_home(17)

  if java21_home then
    table.insert(runtimes, {
      name = "JavaSE-21",
      path = java21_home,
      default = true,
    })
  end

  if java17_home then
    table.insert(runtimes, {
      name = "JavaSE-17",
      path = java17_home,
    })
  end

  return runtimes
end

-- ── Fallback for JAVA_HOME env / cmd_env (your existing logic) ──────────────

local function fallback_java_home()
  local result = vim.fn.system({ "/usr/libexec/java_home", "-v", "17" })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local java_home = vim.trim(result)
  if java_home == "" then
    return nil
  end

  return java_home
end

local function java_cmd_env()
  local java_home = vim.env.JAVA_HOME
  if not java_home or java_home == "" then
    java_home = fallback_java_home()
  end

  if not java_home or java_home == "" then
    return nil
  end

  return {
    JAVA_HOME = java_home,
    PATH = table.concat({ java_home .. "/bin", vim.env.PATH }, ":"),
  }
end

local function java_major_version(env)
  local java_bin = (env and env.JAVA_HOME and env.JAVA_HOME ~= "") and (env.JAVA_HOME .. "/bin/java") or "java"
  local result = vim.system({ java_bin, "-version" }, { env = env, text = true }):wait()
  local version = result.stderr or result.stdout or ""
  local major = version:match('version "(%d+)') or version:match("openjdk (%d+)") or version:match("java (%d+)")
  return major and tonumber(major) or nil
end

local function java_runtime_config()
  local env = java_cmd_env()
  local major = java_major_version(env) or 17

  if major >= 21 then
    return {
      cmd_env = env,
      jdtls = { version = "1.54.0" },
      lombok = { enable = true, version = "1.18.42" },
      java_test = { enable = true, version = "0.43.2" },
      java_debug_adapter = { enable = true, version = "0.58.3" },
      spring_boot_tools = { enable = true, version = "1.55.1" },
      jdk = { auto_install = false },
    }
  end

  return {
    cmd_env = env,
    jdtls = { version = "1.43.0" },
    lombok = { enable = true, version = "1.18.40" },
    java_test = { enable = false, version = "0.40.1" },
    java_debug_adapter = { enable = false, version = "0.58.2" },
    spring_boot_tools = { enable = false, version = "1.55.1" },
    jdk = { auto_install = false },
  }
end

-- ── Maven multi-module root detection ───────────────────────────────────────

local function find_maven_root(path)
  local dir = normalize_dir(path)
  if not dir then
    return nil
  end

  local nearest_pom
  local topmost_pom
  local module_root

  while dir do
    local pom = dir .. "/pom.xml"
    if file_exists(pom) then
      nearest_pom = nearest_pom or dir
      topmost_pom = dir

      local pom_text = read_file(pom)
      if pom_text and pom_text:find("<modules>", 1, true) then
        module_root = dir
      end
    end

    dir = parent_dir(dir)
  end

  return module_root or topmost_pom or nearest_pom
end

local function default_java_root(path)
  local markers = vim.lsp.config.jdtls and vim.lsp.config.jdtls.root_markers
    or {
      "mvnw",
      "gradlew",
      "settings.gradle",
      "settings.gradle.kts",
      ".git",
      "pom.xml",
      "build.gradle",
      "build.gradle.kts",
      "build.xml",
    }

  return vim.fs.root(path, markers)
end

local function java_root_dir(path)
  return find_maven_root(path) or default_java_root(path)
end

-- ── Maven settings detection ────────────────────────────────────────────────

local function resolve_maven_settings(root_path)
  -- Prefer MAVEN_ARGS from environment (direnv already loaded)
  local maven_args = vim.env.MAVEN_ARGS
  if maven_args then
    local settings = maven_args:match("-s%s+(%S+)")
    if settings then
      settings = settings:gsub("$HOME", vim.env.HOME):gsub("${HOME}", vim.env.HOME)
      if file_exists(settings) then
        return settings
      end
    end
  end

  -- Fallback: walk up from root_path looking for .envrc
  local dir = root_path or vim.fn.getcwd()
  while dir do
    local envrc = dir .. "/.envrc"
    local content = read_file(envrc)
    if content then
      local settings = content:match('MAVEN_ARGS="%-s%s+(%S+)"')
        or content:match("MAVEN_ARGS='%-s%s+(%S+)'")
        or content:match("MAVEN_ARGS=%-s%s+(%S+)")
      if settings then
        settings = settings:gsub("$HOME", vim.env.HOME):gsub("${HOME}", vim.env.HOME)
        if file_exists(settings) then
          return settings
        end
      end
    end
    dir = parent_dir(dir)
  end

  return nil
end

-- ── Smart goto definition ───────────────────────────────────────────────────

local function get_lsp_locations(method)
  local params = vim.lsp.util.make_position_params(0, "utf-16")
  local responses = vim.lsp.buf_request_sync(0, method, params, 3000) or {}
  local locations = {}

  for _, response in pairs(responses) do
    local result = response.result
    if result then
      if result.uri or result.targetUri then
        table.insert(locations, result)
      else
        for _, item in ipairs(result) do
          table.insert(locations, item)
        end
      end
    end
  end

  return locations
end

local function location_uri(location)
  return location.uri or location.targetUri
end

local function location_line(location)
  local range = location.range or location.targetSelectionRange or location.targetRange
  return range and range.start and range.start.line or nil
end

local function jump_to_first_location(locations)
  if #locations == 0 then
    return false
  end

  vim.lsp.util.jump_to_location(locations[1], "utf-16", true)
  return true
end

local function smart_java_goto_definition()
  local locations = get_lsp_locations("textDocument/definition")
  if #locations == 0 then
    return vim.notify("No definition found", vim.log.levels.WARN)
  end

  local word = vim.fn.expand("<cword>")
  local current_uri = vim.uri_from_bufnr(0)
  local first = locations[1]
  local first_uri = location_uri(first)
  local first_line = location_line(first)

  -- For injected services/repositories like `chartBiz`, prefer the type definition
  -- instead of the local field declaration in the current file.
  if word:match("^[a-z]") and first_uri == current_uri then
    local type_locations = get_lsp_locations("textDocument/typeDefinition")
    if #type_locations > 0 then
      local type_first = type_locations[1]
      if location_uri(type_first) ~= current_uri or location_line(type_first) ~= first_line then
        return jump_to_first_location(type_locations)
      end
    end
  end

  return jump_to_first_location(locations)
end

-- ── Plugin spec ─────────────────────────────────────────────────────────────

return {
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = function(_, opts)
      opts.root_dir = java_root_dir
    end,
  },
  {
    "nvim-java/nvim-java",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
      {
        "JavaHello/spring-boot.nvim",
        commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
      },
    },
    ft = { "java" },
    keys = {
      { "gd", smart_java_goto_definition, desc = "Java Goto Definition", ft = "java" },
      { "<leader>jr", "<cmd>JavaRunnerRunMain<cr>", desc = "Java Run Main", ft = "java" },
      { "<leader>js", "<cmd>JavaRunnerStopMain<cr>", desc = "Java Stop Main", ft = "java" },
      { "<leader>jo", "<cmd>JavaRunnerToggleLogs<cr>", desc = "Java Toggle Logs", ft = "java" },
      { "<leader>jt", "<cmd>JavaTestRunCurrentClass<cr>", desc = "Java Test Class", ft = "java" },
      { "<leader>jT", "<cmd>JavaTestRunCurrentMethod<cr>", desc = "Java Test Method", ft = "java" },
      { "<leader>jP", "<cmd>JavaProfile<cr>", desc = "Java Profiles", ft = "java" },
    },
    config = function()
      local runtime = java_runtime_config()

      require("java").setup({
        jdtls = runtime.jdtls,
        lombok = runtime.lombok,
        java_test = runtime.java_test,
        java_debug_adapter = runtime.java_debug_adapter,
        spring_boot_tools = runtime.spring_boot_tools,
        jdk = runtime.jdk,
      })

      local lsp_settings = {}

      if runtime.cmd_env then
        lsp_settings.cmd_env = runtime.cmd_env
      end

      local runtimes = configured_runtimes()
      local maven_settings = resolve_maven_settings()

      lsp_settings.root_dir = function(bufnr, on_dir)
        on_dir(java_root_dir(vim.api.nvim_buf_get_name(bufnr)))
      end

      local java_config = {}
      if #runtimes > 0 then
        java_config.configuration = { runtimes = runtimes }
      end
      if maven_settings then
        java_config.configuration = java_config.configuration or {}
        java_config.configuration.maven = { userSettings = maven_settings }
      end
      if next(java_config) then
        lsp_settings.settings = { java = java_config }
      end

      if next(lsp_settings) then
        vim.lsp.config("jdtls", lsp_settings)
      end

      vim.lsp.enable("jdtls")
    end,
  },
}
