return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      for _, parser in ipairs({ "markdown", "markdown_inline" }) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    init = function()
      vim.g.render_markdown_config = {
        file_types = { "markdown" },
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(event)
          vim.keymap.set("n", "<leader>um", "<cmd>RenderMarkdown buf_toggle<cr>", {
            buffer = event.buf,
            desc = "Toggle Markdown Render",
          })
        end,
      })
    end,
  },
}
