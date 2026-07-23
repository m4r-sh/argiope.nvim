local M = {}

M.root = vim.g.argiope_test_root

function M.read_lines(path)
  return vim.fn.readfile(path)
end

function M.fixture_path(name)
  return vim.fs.joinpath(M.root, "tests", "fixtures", "indent", name)
end

function M.integration_fixture_path(name)
  return vim.fs.joinpath(M.root, "tests", "fixtures", "integration", name)
end

function M.new_javascript_buffer(lines)
  vim.cmd("enew!")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].expandtab = true
  vim.bo[bufnr].shiftwidth = 2
  vim.bo[bufnr].softtabstop = 2
  vim.bo[bufnr].tabstop = 2
  vim.bo[bufnr].filetype = "javascript"

  local attached, err = require("argiope").attach(bufnr)
  assert(attached, err)
  return bufnr
end

function M.buffer_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
end

function M.feed(keys)
  local encoded = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(encoded, "xt", false)
end

return M
