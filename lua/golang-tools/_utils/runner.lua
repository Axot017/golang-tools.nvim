local Job = require("plenary.job")
local runner = {}

function runner.sync(cmd, opts)
  local output
  Job:new({
    command = cmd,
    args = opts.args,
    cwd = opts.cwd,
    on_stderr = function(_, data)
      print(data)
    end,
    on_exit = function(data, status)
      output = data:result()
      vim.schedule(function()
        if opts.on_exit then
          opts.on_exit(output, status)
        end
      end)
    end,
  }):sync(60000 --[[1 min]])
  return output
end

return runner
