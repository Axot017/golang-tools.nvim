local config = require("golang-tools.config").get()
local runner = require("golang-tools._utils.runner")
local treesitter = require("golang-tools._utils.treesitter")

local function execute(...)
  local current_file = vim.fn.expand("%")
  local ns = treesitter.get_struct_node_at_pos(unpack(vim.api.nvim_win_get_cursor(0)))
  if ns == nil or ns.name == nil then
    return
  end

  local cmd_args = {
    "-transform", config.gotag.transform,
    "-format", "json",
    "-file", current_file,
    "-struct", ns.name,
  }

  local arg = { ... }
  for _, v in ipairs(arg) do
    table.insert(cmd_args, v)
  end


  local output = runner.sync(config.commands.gomodifytags, {
    args = cmd_args,
    on_exit = function(data, status)
      if not status == 0 then
        error("gotag failed: " .. data)
      end
    end,
  })
  local tagged = vim.json.decode(table.concat(output))
  if
      tagged.errors ~= nil
      or tagged.lines == nil
      or tagged["start"] == nil
      or tagged["start"] == 0
  then
    error("failed to set tags " .. vim.inspect(tagged))
  end

  vim.api.nvim_buf_set_lines(
    0,
    tagged.start - 1,
    tagged.start - 1 + #tagged.lines,
    false,
    tagged.lines
  )
  vim.cmd "write"
end

local M = {}

M.add = function(...)
  local arg = { ... }
  if #arg == 0 then
    arg = { "json" }
  end

  local cmd_args = { "-add-tags" }
  for _, v in ipairs(arg) do
    table.insert(cmd_args, v)
  end

  execute(unpack(cmd_args))
end


M.remove = function(...)
  local arg = { ... }
  if #arg == nil or arg == "" then
    arg = { "json" }
  end

  local cmd_args = { "-remove-tags" }
  for _, v in ipairs(arg) do
    table.insert(cmd_args, v)
  end

  execute(unpack(cmd_args))
end


M.clear = function()
  modify(unpack({ "-clear-tags" }))
end

return M
