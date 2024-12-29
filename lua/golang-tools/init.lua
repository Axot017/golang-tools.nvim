local M = {}


M.setup = function(config)
  local c = require("golang-tools.config")
  c.setup(config)
end

return M
