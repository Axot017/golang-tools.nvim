local config = require("golang-tools.config").get()
local runner = require("golang-tools._utils.runner")
local treesitter = require("golang-tools._utils.treesitter")

local M = {}

M.add_test = function()
  local name = treesitter.get_func_method_node_at_pos(unpack(vim.api.nvim_win_get_cursor(0))).name
  local args = { "-only", name, "-w", vim.fn.expand("%") }

  return runner.sync(config.commands.gotests, {
    args = args,
    on_exit = function(data, status)
      if not status == 0 then
        print("gotests failed: " .. vim.fn.join(data, "\n"))
      else
        local test_file = vim.fn.expand("%:r") .. "_test.go"
        vim.cmd("edit " .. test_file)
      end
    end,
  })
end

return M
