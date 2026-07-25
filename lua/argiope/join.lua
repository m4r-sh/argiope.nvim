local model = require("argiope.model")

local M = {}
local mapping_description = "Join tagged HTML without boundary spaces"
local attached = {}

local function line_at(bufnr, row)
  return vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
end

local function html_template_at(bufnr, row, col)
  local context = model.context_at(bufnr, row, math.max(col, 0))
  local template = context and context.template or nil
  if template and template.registered and template.language == "html" then
    return template
  end
end

local function same_html_template(bufnr, row)
  local left = line_at(bufnr, row)
  local right = line_at(bufnr, row + 1)
  if right == "" and row + 1 >= vim.api.nvim_buf_line_count(bufnr) then
    return false
  end

  local left_indent = #(left:match("^%s*") or "")
  local right_indent = #(right:match("^%s*") or "")
  local left_trimmed = left:gsub("%s+$", "")
  local left_col = math.max(#left_trimmed - 1, left_indent)
  local left_template = html_template_at(bufnr, row, left_col)
  local right_template = html_template_at(bufnr, row + 1, right_indent)
  return left_template
    and right_template
    and left_template.node:equal(right_template.node)
end

local function ends_with_opening_tag(line)
  local tag = line:match("(<[^<]*>%s*)$")
  return tag ~= nil
    and tag:match("^<%s*[%a][%w:_%-]*") ~= nil
    and tag:match("/>%s*$") == nil
end

local function starts_with_closing_tag(line)
  return line:match("^%s*</%s*[%a][%w:_%-]*") ~= nil
end

local function compact_boundary(bufnr, row)
  if not same_html_template(bufnr, row) then
    return false
  end

  return ends_with_opening_tag(line_at(bufnr, row))
    or starts_with_closing_tag(line_at(bufnr, row + 1))
end

local function compact_join(bufnr, row)
  local left = line_at(bufnr, row):gsub("%s+$", "")
  local right = line_at(bufnr, row + 1):gsub("^%s+", "")
  vim.api.nvim_buf_set_lines(bufnr, row, row + 2, false, { left .. right })
  vim.api.nvim_win_set_cursor(0, { row + 1, math.max(#left - 1, 0) })
end

local function native_join(count)
  local prefix = count > 0 and tostring(count) or ""
  vim.cmd.normal({ args = { prefix .. "J" }, bang = true })
end

local function join_range(bufnr, row, count)
  local available = vim.api.nvim_buf_line_count(bufnr) - row
  local line_count = math.min(math.max(count > 0 and count or 2, 2), available)

  if line_count < 2 then
    return
  end

  local has_compact_boundary = false
  for offset = 0, line_count - 2 do
    if compact_boundary(bufnr, row + offset) then
      has_compact_boundary = true
      break
    end
  end

  if not has_compact_boundary then
    native_join(count)
    return
  end

  for index = 1, line_count - 1 do
    if index > 1 then
      pcall(vim.cmd, "undojoin")
    end
    if compact_boundary(bufnr, row) then
      compact_join(bufnr, row)
    else
      native_join(0)
    end
  end
end

function M.join(bufnr, count)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  count = count == nil and vim.v.count or count
  join_range(bufnr, vim.api.nvim_win_get_cursor(0)[1] - 1, count)
end

function M.join_visual(bufnr)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local start_row = vim.api.nvim_buf_get_mark(bufnr, "<")[1]
  local end_row = vim.api.nvim_buf_get_mark(bufnr, ">")[1]
  if start_row == 0 or end_row == 0 then
    return
  end
  if start_row > end_row then
    start_row, end_row = end_row, start_row
  end

  vim.api.nvim_win_set_cursor(0, { start_row, 0 })
  join_range(bufnr, start_row - 1, end_row - start_row + 1)
end

local function current_mapping(bufnr, mode)
  return vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.maparg("J", mode, false, true)
  end)
end

function M.attach(bufnr)
  attached[bufnr] = attached[bufnr] or {}
  local installed = false

  if not attached[bufnr].n and next(current_mapping(bufnr, "n")) == nil then
    vim.keymap.set("n", "J", function()
      M.join(bufnr)
    end, {
      buffer = bufnr,
      desc = mapping_description,
    })
    attached[bufnr].n = true
    installed = true
  end

  if not attached[bufnr].x and next(current_mapping(bufnr, "x")) == nil then
    vim.keymap.set(
      "x",
      "J",
      (":<C-U>lua require('argiope.join').join_visual(%d)<CR>"):format(bufnr),
      {
        buffer = bufnr,
        desc = mapping_description,
        silent = true,
      }
    )
    attached[bufnr].x = true
    installed = true
  end

  return installed
end

function M.detach(bufnr)
  if not attached[bufnr] then
    return
  end

  for _, mode in ipairs({ "n", "x" }) do
    local mapping = current_mapping(bufnr, mode)
    if attached[bufnr][mode] and mapping.desc == mapping_description then
      pcall(vim.keymap.del, mode, "J", { buffer = bufnr })
    end
  end
  attached[bufnr] = nil
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("argiope_join", { clear = true }),
  callback = function(event)
    attached[event.buf] = nil
  end,
})

return M
