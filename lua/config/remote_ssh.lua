local M = {}

local control_dir = vim.fn.stdpath("state") .. "/ssh-control"
local control_path = control_dir .. "/%C"

local function multiplex_options()
  vim.fn.mkdir(control_dir, "p", 448)
  return {
    "-o",
    "ControlMaster=auto",
    "-o",
    "ControlPersist=15m",
    "-o",
    "ControlPath=" .. control_path,
  }
end

local function with_multiplexing(command)
  local result = { command[1] }
  local index = 2

  while index <= #command do
    if command[index] == "-o" and command[index + 1] then
      local option = command[index + 1]
      if option:match("^ControlMaster=") or option:match("^ControlPersist=") or option:match("^ControlPath=") then
        index = index + 2
      else
        table.insert(result, command[index])
        table.insert(result, option)
        index = index + 2
      end
    else
      table.insert(result, command[index])
      index = index + 1
    end
  end

  local options = multiplex_options()
  for option_index = #options, 1, -1 do
    table.insert(result, 2, options[option_index])
  end
  return result
end

function M.command(host, command)
  return with_multiplexing({ "ssh", host, command })
end

function M.enable_plugin_multiplexing()
  local ssh_utils = require("async-remote-write.ssh_utils")
  if ssh_utils._personal_multiplexing_enabled then
    return
  end

  for _, function_name in ipairs({ "build_ssh_cmd", "build_ssh_command", "build_scp_cmd" }) do
    local original = ssh_utils[function_name]
    if original then
      ssh_utils[function_name] = function(...)
        return with_multiplexing(original(...))
      end
    end
  end

  ssh_utils._personal_multiplexing_enabled = true
end

return M
