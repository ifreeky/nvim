return {
  -- 主题插件配置
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true, -- 延迟加载
  },
  {
    "folke/tokyonight.nvim",
    lazy = true, -- 延迟加载
  },
  {
    "navarasu/onedark.nvim",
    lazy = true, -- 延迟加载
  },
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false, -- 确保 cyberdream 立即加载
    priority = 1000, -- 确保 cyberdream 在其他主题之前加载
    opts = {
      transparent = true,
    },
  },

  -- 配置 LazyVim 使用 cyberdream 作为默认主题
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "cyberdream", -- 设置默认配色
    },
  },
}
