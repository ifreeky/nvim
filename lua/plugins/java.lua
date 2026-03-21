local function jdtls_java_env()
  local result = vim.fn.system({ "/usr/libexec/java_home", "-v", "21" })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local java_home = vim.trim(result)
  if java_home == "" then
    return nil
  end

  return {
    JAVA_HOME = java_home,
    PATH = table.concat({ java_home .. "/bin", vim.env.PATH }, ":"),
  }
end

return {
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
    config = function()
      require("java").setup({
        jdk = {
          auto_install = false,
        },
      })

      local env = jdtls_java_env()
      if env then
        vim.lsp.config("jdtls", {
          cmd_env = env,
        })
      end

      vim.lsp.enable("jdtls")
    end,
  },
}
