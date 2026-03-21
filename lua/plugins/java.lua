local java = require("config.helpers.java")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if not vim.tbl_contains(opts.ensure_installed, "java") then
        table.insert(opts.ensure_installed, "java")
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      for _, pkg in ipairs({ "google-java-format", "jdtls" }) do
        if not vim.tbl_contains(opts.ensure_installed, pkg) then
          table.insert(opts.ensure_installed, pkg)
        end
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.java = { "google-java-format" }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      local server = opts.servers.jdtls == true and {} or opts.servers.jdtls or {}
      local existing_on_attach = server.on_attach

      server.cmd = java.jdtls_cmd()
      server.root_dir = java.root_dir
      server.single_file_support = false
      server.settings = vim.tbl_deep_extend("force", server.settings or {}, {
        java = {
          eclipse = {
            downloadSources = false,
          },
          maven = {
            downloadSources = false,
          },
          configuration = {
            updateBuildConfiguration = "interactive",
          },
          implementationsCodeLens = {
            enabled = false,
          },
          inlayHints = {
            parameterNames = {
              enabled = "none",
            },
          },
          referencesCodeLens = {
            enabled = false,
          },
        },
      })
      server.on_attach = function(client, bufnr)
        if existing_on_attach then
          existing_on_attach(client, bufnr)
        end
        vim.diagnostic.enable(false, { bufnr = bufnr })
      end

      opts.servers.jdtls = server
    end,
  },
}
