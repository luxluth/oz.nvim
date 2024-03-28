---@class Utils
local utils = {}

---@param bufnr integer
---@return string[]
function utils.get_visual(bufnr)
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))
  local start_line, end_line

  if ls < le or (ls == le and cs < ce) then
    start_line = ls
    end_line = le
  else
    start_line = le
    end_line = ls
  end

  return vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
end

return utils
