local M = {}
local started = {}
local html = require("argiope.html")
local markdown = require("argiope.markdown")

local function highlighter_active(bufnr)
  local highlighter = vim.treesitter.highlighter
  return highlighter and highlighter.active and highlighter.active[bufnr] ~= nil
end

function M.attach(bufnr, language)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  language = language or "javascript"
  local already_active = highlighter_active(bufnr)
  local ok, err = pcall(vim.treesitter.start, bufnr, language)
  if not ok then
    return false, err
  end

  started[bufnr] = started[bufnr] or not already_active
  if language == "javascript" then
    html.attach(bufnr)
    markdown.attach(bufnr)
  else
    html.detach(bufnr)
    markdown.detach(bufnr)
  end
  vim.b[bufnr].argiope_highlight_attached = true
  return true
end

function M.detach(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if started[bufnr] then
    pcall(vim.treesitter.stop, bufnr)
  end
  started[bufnr] = nil
  html.detach(bufnr)
  markdown.detach(bufnr)

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.b[bufnr].argiope_highlight_attached = nil
  end
end

return M
