---@class LogBuffer
local LogBuf = {
  ---@type integer
  nr = vim.api.nvim_create_buf(true, false),
  ---@type string[]
  content = {},
  ---@type number
  max_content_lines = 500,
  win = {
    open = false,
    ---@type number
    id = nil,
  },
}

function LogBuf:clear_buf()
  vim.api.nvim_buf_set_lines(self.nr, 0, -1, false, {})
end

---@param lines string[]
function LogBuf:set_buf_lines(lines)
  self:clear_buf()
  vim.api.nvim_buf_set_lines(self.nr, 0, -1, false, lines)
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
  if self.win.open ~= true then
    self.win.id = vim.api.nvim_open_win(self.nr, false, {
      split = "left",
      title = "[oz.nvim::Logger]",
      anchor = "SW",
    })
    self.win.open = true
  end
end

function LogBuf:close_log()
  if self.win.open ~= false then
    vim.api.nvim_win_close(self.win.id, true)
    self.win.id = nil
    self.win.open = false
  end
end

function LogBuf:toogle_log()
  if self.win.open then
    self:close_log()
  else
    self:open_log()
  end
end

return LogBuf
