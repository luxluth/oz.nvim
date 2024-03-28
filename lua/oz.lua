-- main module file
local engine = require("oz.engine")
local utils = require("oz.utils")

---@class Options
local opts = {
  ozengine_path = "ozengine",
  show_compiler_output = true,
  linter = false,
  keymap = "<C-r>",
}

---@class OzNvim
local M = {}

---@type Options
M.opts = opts

---@param args Options?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
function M.setup(args)
  M.opts = vim.tbl_deep_extend("force", M.opts, args or {})
end

function M.engine_path()
  engine.path(M.opts.ozengine_path)
  return M.opts.ozengine_path
end

---@param bufnr integer
---@return string
local get_buffer_text = function(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end

---Run an .oz buffer
---@param bufnr integer
function M.feed_file(bufnr)
  local filetype = vim.api.nvim_get_option_value("filetype", {
    buf = bufnr,
  })

  if filetype ~= "oz" then
    return
  end

  local file_name = vim.api.nvim_buf_get_name(bufnr)
  vim.notify(get_buffer_text(bufnr), vim.log.levels.INFO)
end

---Feed a selection into the engine
---@param bufnr integer
function M.feed_selection(bufnr)
  local filetype = vim.api.nvim_get_option_value("filetype", {
    buf = bufnr,
  })

  if filetype ~= "oz" then
    return
  end

  local selected_text = table.concat(utils.get_visual(bufnr), "\n")

  vim.notify(selected_text, vim.log.levels.INFO, {})
  local file_name = vim.api.nvim_buf_get_name(bufnr)
end

---Start the ozengine server
function M.start_engine()
  engine.start(M)
end

---Shutdown the ozengine server
function M.shutdown_engine()
  engine.shutdown()
end

---Restart the ozengine server
function M.restart_engine()
  engine.restart(M)
end

return M
