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
  },
  {
    "navarasu/onedark.nvim",
    lazy = true, -- 延迟加载
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "NeoSolarized", -- 设置默认配色
    },
  },
}
