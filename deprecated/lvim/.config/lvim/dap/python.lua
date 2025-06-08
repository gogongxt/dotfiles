local dap = require('dap')
dap.configurations.python = {
  {
    type = 'python';
    request = 'launch';
    name = "Launch file";
    program = "${file}";
    pythonPath = function()
      return '/usr/bin/python'
      -- return '/home/gxt_kt/miniconda3/bin/python3'
    end;
  },
}
dap.adapters.python = {
  type = "executable";
  -- command = '/usr/bin/python';
  -- command = '/home/gxt_kt/miniconda3/bin/python3.10';
  command='/home/gxt_kt/.local/share/lvim/mason/bin/debugpy-adapter';
  -- args = { '-m', 'debugpy.adapter' };
  args = {};
}
