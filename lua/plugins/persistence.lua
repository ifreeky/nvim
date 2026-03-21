local helpers = require("config.helpers.persistence")

return {
  {
    "folke/persistence.nvim",
    lazy = false,
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ifreeky_restore_buffer_features", { clear = true }),
        pattern = "PersistenceLoadPost",
        callback = function()
          vim.g.ifreeky_restore_buffers_pending = true
          vim.schedule(function()
            if package.loaded["nvim-treesitter"] then
              helpers.refresh_session_buffers()
              vim.g.ifreeky_restore_buffers_pending = false
            end
          end)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ifreeky_restore_buffer_features_after_verylazy", { clear = true }),
        pattern = "VeryLazy",
        callback = function()
          if vim.g.ifreeky_restore_buffers_pending then
            helpers.refresh_session_buffers()
            vim.g.ifreeky_restore_buffers_pending = false
          end
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("ifreeky_auto_restore_session", { clear = true }),
        callback = function()
          if vim.g.started_with_stdin then
            return
          end

          local argc = vim.fn.argc()
          local argv0 = argc > 0 and vim.fn.argv(0) or nil
          local entering_dir = argc == 1 and helpers.is_dir(argv0)
          local explorer_dir = entering_dir and argv0 or nil

          if not (argc == 0 or entering_dir) then
            return
          end

          local persistence = require("persistence")
          local has_session = vim.fn.filereadable(persistence.current()) == 1
            or vim.fn.filereadable(persistence.current({ branch = false })) == 1

          if has_session then
            persistence.load()
            helpers.open_explorer(explorer_dir)
            return
          end

          if entering_dir then
            helpers.open_explorer(explorer_dir)
          end
        end,
      })
    end,
  },
}
