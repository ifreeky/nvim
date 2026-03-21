local M = {}

function M.is_dir(path)
  return path ~= nil and vim.fn.isdirectory(vim.fn.fnamemodify(path, ":p")) == 1
end

function M.open_explorer(path)
  local dir = path and vim.fn.fnamemodify(path, ":p") or nil

  vim.schedule(function()
    local ok, command = pcall(require, "neo-tree.command")
    if ok then
      command.execute({
        action = "show",
        source = "filesystem",
        position = "left",
        dir = dir or vim.uv.cwd(),
      })
    end
  end)
end

function M.refresh_session_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        if vim.bo[buf].filetype == "" then
          local ft = vim.filetype.match({ buf = buf, filename = name })
          if ft and ft ~= "" then
            vim.bo[buf].filetype = ft
          end
        end

        if vim.bo[buf].filetype ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
          pcall(vim.treesitter.start, buf)
        end
      end
    end
  end
end

return M
