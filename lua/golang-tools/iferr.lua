local config = require("golang-tools.config").get()

local M = {}

M.iferr = function()
  local cmd = config.commands.iferr

  local offset = vim.fn.wordcount().cursor_bytes
  local position = vim.fn.getcurpos()[2]
  local result = vim.fn.systemlist((config.commands.iferr .. " -pos " .. offset), vim.fn.bufnr "%")

  if vim.v.shell_error ~= 0 then
    print("Error: " .. vim.fn.join(result, "\n"))
    return
  end

  vim.fn.append(position, result)
  vim.cmd [[silent normal! j=2j]]
  vim.fn.setpos(".", position)
end

return M
