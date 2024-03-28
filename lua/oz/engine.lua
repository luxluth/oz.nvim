---@class OzEngine
local M = {}

---@class EngineConnector
local EC = {
  server = {
    ---@type number
    pid = nil,
    active = false,
  },
  compiler = {
    ---@type number
    pid = nil,
    active = false,
  },
}

---@param port string
function EC:spinsup_compiler(port)
  local command = { "socat", "-", string.format("TCP:localhost:%s", port) }
  vim.notify(string.format("TCP:localhost:%s", port), vim.log.levels.WARN, { title = "oz.nvim" })

  self.compiler.pid = vim.fn.jobstart(command, {
    ---@param data string
    on_stdout = function(_, data, _) end,
    on_stderr = function(_, data, _)
      vim.notify(data, vim.log.levels.WARN, { title = "oz.nvim" })
    end,
    on_exit = function(_, _, _)
      vim.notify(command .. " " .. "has exited", vim.log.levels.WARN, { title = "oz.nvim" })
    end,
  })

  self.compiler.active = true
end

---Start the ozengine server
---@param instance OzNvim
function EC:start(instance)
  local command = { instance.opts.ozengine_path, "x-oz://system/OPI.ozf" }
  if self.server.pid == nil then
    self.server.pid = vim.fn.jobstart(command, {
      ---@param data string
      on_data = function(_, data, _)
        -- check for socket if not connected yet
        if self.server.active == false then
          local server_port, _debug_port = data:match("'oz%-socket (%d+) (%d+)'")
          vim.notify(server_port, vim.log.levels.INFO, { title = "oz.nvim" })
          if self.compiler.active == false then
            self.spinsup_compiler(self, server_port)
          end
        end
      end,
      on_stderr = function(_, data, _)
        vim.notify(data, vim.log.levels.TRACE, { title = "oz.nvim" })
      end,
      on_exit = function(_, _, _)
        vim.notify(command .. " " .. "has exited", vim.log.levels.WARN, { title = "oz.nvim" })
      end,
    })

    self.server.active = true
    vim.notify("ozengine has been started...", vim.log.levels.INFO, { title = "oz.nvim" })
  end
end
-- ozengine x-oz://system/OPI.ozf

---Shutdown the ozengine server
function EC:shutdown()
  if self.server.pid ~= nil then
    vim.fn.jobstop(self.server.pid)
    self.server.pid = nil
    self.server.active = false
  end
  if self.compiler.pid ~= nil then
    vim.fn.jobstop(self.compiler.pid)
    self.compiler.pid = nil
    self.compiler.active = false
  end
end

---@param str string[]
function EC:send(str)
  if self.compiler.active then
    vim.fn.chansend(self.compiler.pid, str)
  end
end

M.path = function(path)
  vim.notify("The engine path is set to " .. "`" .. path .. "`", vim.log.levels.INFO, { title = "oz.nvim" })
end

---Start the ozengine server
---@param instance OzNvim
M.start = function(instance)
  EC:start(instance)
end

---Shutdown the ozengine server
function M.shutdown()
  EC:shutdown()
end

---Restart the ozengine server
---@param instance OzNvim
function M.restart(instance)
  EC:shutdown()
  EC:start(instance)
end

return M
