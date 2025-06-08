local dap = require "dap"
dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}", -- This configuration will launch the current file if used.
  },
}
dap.adapters.python = {
  type = "executable",
  command = "/usr/bin/python3",
  -- command = "/home/gxt_kt/miniconda3/bin/python3",
  args = { "-m", "debugpy.adapter" },
}
