local M = {}

local _default = {
  commands = {
    go = "go",
    gomodifytags = "gomodifytags",
    gotests = "gotests",
    impl = "impl",
    iferr = "iferr",
  },
  gotag = {
    transform = "snakecase",
  },
}

local _config = _default

M.setup = function(config)
  _config = vim.tbl_deep_extend("force", _default, config)
end

M.get = function()
  return _config
end

return M
