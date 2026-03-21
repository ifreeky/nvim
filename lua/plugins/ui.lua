return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.lsp = opts.lsp or {}
      opts.lsp.progress = opts.lsp.progress or {}
      opts.lsp.progress.enabled = true
      opts.lsp.progress.throttle = 1000 / 3
      opts.lsp.progress.view = "notify"

      opts.views = opts.views or {}
      opts.views.notify = opts.views.notify or {}
      opts.views.notify.merge = true
      opts.views.notify.replace = true
    end,
  },
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.offsets = opts.options.offsets or {}

      for _, offset in ipairs(opts.options.offsets) do
        if offset.filetype == "neo-tree" then
          offset.text = ""
        end
      end
    end,
  },
}
