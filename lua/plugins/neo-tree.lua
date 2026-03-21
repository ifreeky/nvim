return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        group_empty_dirs = true,
        scan_mode = "deep",
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true,
        },
      },
      git_status = {
        group_empty_dirs = true,
      },
      window = {
        mappings = {
          ["L"] = "expand_all_subnodes",
          ["H"] = "close_all_subnodes",
        },
      },
    },
  },
}
