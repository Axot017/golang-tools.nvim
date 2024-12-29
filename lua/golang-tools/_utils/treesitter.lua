local ts_query = require "nvim-treesitter.query"
local parsers = require "nvim-treesitter.parsers"
local locals = require "nvim-treesitter.locals"

local function get_name_defaults()
  return {
    ["func"] = "function",
    ["if"] = "if",
    ["else"] = "else",
    ["for"] = "for",
  }
end

local function intersects(row, col, sRow, sCol, eRow, eCol)
  if sRow > row or eRow < row then
    return false
  end

  if sRow == row and sCol > col then
    return false
  end

  if eRow == row and eCol < col then
    return false
  end

  return true
end

local function intersect_nodes(nodes, row, col)
  local found = {}
  for idx = 1, #nodes do
    local node = nodes[idx]
    local sRow = node.dim.s.r
    local sCol = node.dim.s.c
    local eRow = node.dim.e.r
    local eCol = node.dim.e.c

    if intersects(row, col, sRow, sCol, eRow, eCol) then
      table.insert(found, node)
    end
  end

  return found
end

local function get_all_nodes(query, lang, _, bufnr, pos_row, _)
  bufnr = bufnr or 0
  pos_row = pos_row or 30000

  local ok, parsed_query = pcall(function()
    return vim.treesitter.query.parse(lang, query)
  end)
  if not ok then
    return nil
  end

  local parser = parsers.get_parser(bufnr, lang)
  local root = parser:parse()[1]:root()
  local start_row, _, end_row, _ = root:range()
  local results = {}

  for match in ts_query.iter_prepared_matches(parsed_query, root, bufnr, start_row, end_row) do
    local sRow, sCol, eRow, eCol, declaration_node
    local type, name, op = "", "", ""
    locals.recurse_local_nodes(match, function(_, node, path)
      local idx = string.find(path, ".[^.]*$")
      op = string.sub(path, idx + 1, #path)
      type = string.sub(path, 1, idx - 1)

      if op == "name" then
        name = vim.treesitter.get_node_text(node, bufnr)
      elseif op == "declaration" or op == "clause" then
        declaration_node = node
        sRow, sCol, eRow, eCol = node:range()
        sRow = sRow + 1
        eRow = eRow + 1
        sCol = sCol + 1
        eCol = eCol + 1
      end
    end)

    if declaration_node ~= nil then
      table.insert(results, {
        declaring_node = declaration_node,
        dim = { s = { r = sRow, c = sCol }, e = { r = eRow, c = eCol } },
        name = name,
        operator = op,
        type = type,
      })
    end
  end

  return results
end



local function nodes_at_cursor(query, default, bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
  if row == nil or col == nil then
    row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
  end

  local nodes = get_all_nodes(query, ft, default, bufnr, row, col)
  if nodes == nil then
    return nil
  end

  nodes = intersect_nodes(nodes, row, col)
  if nodes == nil or #nodes == 0 then
    return nil
  end

  return nodes
end

local queries = {
  struct_block =
  [[((type_declaration (type_spec name:(type_identifier) @struct.name type: (struct_type)))@struct.declaration)]],
  em_struct_block = [[(field_declaration name:(field_identifier)@struct.name type: (struct_type)) @struct.declaration]],
  package = [[(package_clause (package_identifier)@package.name)@package.clause]],
  interface =
  [[((type_declaration (type_spec name:(type_identifier) @interface.name type:(interface_type)))@interface.declaration)]],
  method_name =
  [[((method_declaration receiver: (parameter_list)@method.receiver name: (field_identifier)@method.name body:(block))@method.declaration)]],
  func = [[((function_declaration name: (identifier)@function.name) @function.declaration)]],
}

local M = {}

M.get_func_method_node_at_pos = function(row, col, bufnr)
  local query = queries.func .. " " .. queries.method_name
  local bufn = bufnr or vim.api.nvim_get_current_buf()
  local ns = nodes_at_cursor(query, get_name_defaults(), bufn, row, col)
  if ns ~= nil then
    return ns[#ns]
  end
end

M.get_struct_node_at_pos = function(row, col, bufnr)
  local query = queries.struct_block .. " " .. queries.em_struct_block
  local bufn = bufnr or vim.api.nvim_get_current_buf()
  local ns = nodes_at_cursor(query, get_name_defaults(), bufn, row, col)
  if ns ~= nil then
    return ns[#ns]
  end
end

return M
