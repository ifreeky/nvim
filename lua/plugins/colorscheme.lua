return {
  -- 主题插件配置
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true, -- 延迟加载
  },
  {
    "Tsuzat/NeoSolarized.nvim",
    lazy = false, -- 延迟加载
    priority = 1000,
    config = function()
      vim.cmd([[ colorscheme NeoSolarized ]])
    end,
  },
  {
    "navarasu/onedark.nvim",
    lazy = true, -- 延迟加载
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = true, -- 确保 cyberdream 立即加载
    priority = 1000, -- 确保 cyberdream 在其他主题之前加载
    opts = {
      transparent = true,
      borderless_telescope = true,
      terminal_colors = true,
    },
  },

  -- 配置 LazyVim 使用 cyberdream 作为默认主题
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "NeoSolarized", -- 设置默认配色
    },
  },
}
