local LogBuf = require("oz.log")
local uv = vim.uv

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
    ---@type uv.uv_tcp_t|nil
    client = nil,
    active = false,
  },
}

---@param port string
function EC:spinsup_compiler(port)
  uv.check_start(uv.new_check(), function() end)

  local client = uv.new_tcp()
  local iport = tonumber(port)

  if client ~= nil and iport ~= nil then
    self.compiler.client = client
    client:connect("127.0.0.1", iport, function(err)
      if err then
        vim.notify(
          "Unable to connect to the ozengine server\n[CAUSE] " .. err,
          vim.log.levels.ERROR,
          { title = "oz.nvim" }
        )
      else
        self.compiler.active = true
        client:read_start(function(read_err, chunk)
          if read_err then
            vim.notify("ozengine server read error\n[CAUSE] " .. read_err, vim.log.levels.ERROR, { title = "oz.nvim" })
          elseif chunk then
            vim.schedule(function()
              LogBuf:push(vim.split(chunk, "\n", { trimempty = true }))
            end)
          else
            vim.notify("The ozengine server has disconnected", vim.log.levels.WARN, { title = "oz.nvim" })
            uv.close(client, function()
              vim.notify("The listenner has been closed", vim.log.levels.WARN, { title = "oz.nvim" })
              self.compiler.active = false
              self.compiler.client = nil
            end)
          end
        end)
      end
    end)
  else
    vim.notify("Unable to connect to the ozengine througth TCP", vim.log.levels.WARN, { title = "oz.nvim" })
  end
end

---Start the ozengine server
---@param instance OzNvim
function EC:start(instance)
  local command = { instance.opts.ozengine_path, "x-oz://system/OPI.ozf" }
  if self.server.pid == nil then
    self.server.pid = vim.fn.jobstart(command, {
      ---@param data string[]
      on_stdout = function(_, data, _)
        -- check for socket if not connected yet
        if self.server.active == false then
          local server_port, _ = string.match(table.concat(data, "\n"), "'oz%-socket (%d+) (%d+)'")
          if self.compiler.active == false then
            self:spinsup_compiler(server_port)
          end
          self.server.active = true
        end
      end,
      on_stderr = function(_, _, _) end,
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
    uv.close(self.compiler.client)
    self.compiler.client = nil
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
    uv.write(
      self.compiler.client,
      message.data
        .. "\n%%oz-nvim:linter:filename:"
        .. message.filename
        .. ":line:"
        .. message.line
        .. ":char:"
        .. message.character
        .. "\n\x04\n",
      function(err)
        if err then
          vim.notify(
            "An error occured while sending the feed to the client\n[CAUSE] " .. err,
            vim.log.levels.WARN,
            { title = "oz.nvim" }
          )
        end
      end
    )
    vim.notify(
      string.format("feed sended ... (localhost:%s)", self.compiler.client:getsockname().port),
      vim.log.levels.TRACE,
      { title = "oz.nvim" }
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
