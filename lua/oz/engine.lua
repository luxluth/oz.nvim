local LogBuf = require("oz.log")

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

  self.compiler.pid = vim.fn.jobstart(command, {
    ---@param data string[]
    on_stdout = function(_, data, _)
      LogBuf:push(data)
    end,
    on_stderr = function(_, data, _)
      vim.notify(table.concat(data, "\n"), vim.log.levels.WARN, { title = "oz.nvim" })
    end,
    on_exit = function(_, _, _)
      vim.notify(table.concat(command, " ") .. " " .. "has exited", vim.log.levels.WARN, { title = "oz.nvim" })
    end,
  })

  if self.compiler.pid > 0 then
    self.compiler.active = true
  else
    vim.notify("Unable to connect to the ozengine by TCP", vim.log.levels.WARN, { title = "oz.nvim" })
    self.compiler.active = false
  end
end

---Start the ozengine server
---@param instance OzNvim
function EC:start(instance)
  local command = { instance.opts.ozengine_path, "x-oz://system/OPI.ozf" }
  if self.server.pid == nil then
    self.server.pid = vim.fn.jobstart(command, {
      ---@param data string[]
      on_stdout = function(id, data, event)
        -- check for socket if not connected yet
        if self.server.active == false then
          local server_port, debug_port = string.match(table.concat(data, "\n"), "'oz%-socket (%d+) (%d+)'")
          -- vim.notify(server_port, vim.log.levels.INFO, { title = "oz.nvim" })
          if self.compiler.active == false then
            self.spinsup_compiler(self, server_port)
          end
          self.server.active = true
        end
      end,
      on_stderr = function(id, data, event)
        -- vim.notify(data, vim.log.levels.TRACE, { title = "oz.nvim" })
      end,
      on_exit = function(_, _, _)
        vim.notify(table.concat(command, " ") .. " " .. "has exited", vim.log.levels.WARN, { title = "oz.nvim" })
      end,
    })

    if self.server.pid > 0 then
      vim.notify("ozengine has been started...", vim.log.levels.INFO, { title = "oz.nvim" })
    else
      vim.notify(
        "Unable to start the ozengine with the path " .. instance.opts.ozengine_path,
        vim.log.levels.ERROR,
        { title = "oz.nvim" }
      )
      self.server.active = false
    end
  end
end

---Shutdown the ozengine server
function EC:shutdown()
  if self.compiler.active then
    -- self:send({
    --   character = 0,
    --   data = "{Application.exit 0}",
    --   filename = "",
    --   line = 0,
    -- })
    vim.fn.jobstop(self.compiler.pid)
    self.compiler.pid = nil
    self.compiler.active = false
    LogBuf:reset()
  end

  if self.server.active then
    vim.fn.jobstop(self.server.pid)
    self.server.pid = nil
    self.server.active = false
  end
end

---@class CompilerMessage
---@field character number
---@field data string
---@field filename string
---@field line number

---@param message CompilerMessage
function EC:send(message)
  if self.compiler.active then
    vim.notify(string.format("feed send to pid %d", self.compiler.pid), vim.log.levels.TRACE, { title = "oz.nvim" })
    vim.fn.chansend(
      self.compiler.pid,
      message.data
        .. "\n%%oz-nvim:linter:filename:"
        .. message.filename
        .. ":line:"
        .. message.line
        .. ":char:"
        .. message.character
        .. "\n\x04\n"
    )
  end
end

---Send code to the engine
---@param message CompilerMessage
M.send = function(message)
  EC:send(message)
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

function M.openlogs()
  LogBuf:open_log()
end

-- function M.closelogs()
--   LogBuf:close_log()
-- end
--
-- function M.tooglelogs()
--   LogBuf:toogle_log()
-- end

return M
