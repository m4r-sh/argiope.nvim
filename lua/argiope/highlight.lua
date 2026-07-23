local M = {}
local started = {}
local markdown = require("argiope.markdown")

local function highlighter_active(bufnr)
  local highlighter = vim.treesitter.highlighter
  return highlighter and highlighter.active and highlighter.active[bufnr] ~= nil
end

function M.attach(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local already_active = highlighter_active(bufnr)
  local ok, err = pcall(vim.treesitter.start, bufnr, "javascript")
  if not ok then
    return false, err
  end

  started[bufnr] = started[bufnr] or not already_active
  markdown.attach(bufnr)
  vim.b[bufnr].argiope_highlight_attached = true
  return true
end

function M.detach(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if started[bufnr] then
    pcall(vim.treesitter.stop, bufnr)
  end
  started[bufnr] = nil
  markdown.detach(bufnr)

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.b[bufnr].argiope_highlight_attached = nil
  end
end

return M
