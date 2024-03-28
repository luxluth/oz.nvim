---@class LogBuffer
local LogBuf = {
  ---@type string[]
  content = {},
  ---@type number
  max_content_lines = 500,
  buf = {
    ---@type integer
    nr = nil,
    open = false,
  },
}

function LogBuf:clear_buf()
  if self.buf.nr ~= nil then
    vim.api.nvim_buf_set_lines(self.buf.nr, 0, -1, false, {})
  end
end

---@param lines string[]
function LogBuf:set_buf_lines(lines)
  self:clear_buf()
  if self.buf.nr ~= nil then
    vim.api.nvim_buf_set_lines(self.buf.nr, 0, -1, false, lines)
  end
end

function LogBuf:sync_lines()
  self:clear_buf()
  if self.buf.nr ~= nil then
    vim.api.nvim_buf_set_lines(self.buf.nr, 0, -1, false, self.content)
  end
end

---@param lines string[]
function LogBuf:push(lines)
  local total_lines = #self.content + #lines
  if total_lines <= self.max_content_lines then
    for _, line in ipairs(lines) do
      table.insert(self.content, line)
    end
  else
    local excess_lines = total_lines - self.max_content_lines
    for i = 1, excess_lines do
      table.remove(self.content, 1)
    end
    for _, line in ipairs(lines) do
      table.insert(self.content, line)
    end
  end

  self:set_buf_lines(self.content)
end

function LogBuf:open_log()
  if self.buf.open ~= true then
    self.buf.nr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(self.buf.nr, "[oz.nvim::Logger]")
    self.buf.open = true
    self:sync_lines()
  end
end

function LogBuf:close_log()
  if self.buf.open ~= false then
    if self.buf.nr ~= nil then
      local win_id = vim.fn.bufwinid(self.buf.nr)
      if win_id >= 0 then
        vim.api.nvim_win_close(win_id, true)
      end
      vim.api.nvim_buf_delete(self.buf.nr, { force = true })
    end
    self.buf.nr = nil
    self.buf.open = false
  end
end

function LogBuf:toogle_log()
  if self.buf.open then
    self:close_log()
  else
    self:open_log()
  end
end

return LogBuf
