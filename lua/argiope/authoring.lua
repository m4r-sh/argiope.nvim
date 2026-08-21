local model = require("argiope.model")

local M = {}
local mapping_description = "Open and close an embedded HTML element"
local attached = {}

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function current_mapping(bufnr)
  return vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.maparg("<CR>", "i", false, true)
  end)
end

local function indentation(bufnr, width)
  if vim.bo[bufnr].expandtab then
    return string.rep(" ", width)
  end
  local tabstop = math.max(vim.bo[bufnr].tabstop, 1)
  return string.rep("\t", math.floor(width / tabstop))
    .. string.rep(" ", width % tabstop)
end

function M.enter(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local context = model.context_at(bufnr, row, math.max(col - 1, 0))
  local template = context and context.template or nil
  if
    not template
    or (template.language ~= "html" and template.language ~= "svg")
    or context.interpolation
  then
    return termcodes("<CR>")
  end

  local tag = require("argiope.html").opening_tag_at_cursor(
    bufnr,
    template,
    row,
    col
  )
  if not tag then
    return termcodes("<CR>")
  end

  local shiftwidth = vim.bo[bufnr].shiftwidth
  if shiftwidth == 0 then
    shiftwidth = vim.bo[bufnr].tabstop
  end
  local width = vim.fn.indent(row + 1) + shiftwidth
  return termcodes(
    ("<CR></%s><Esc>==O<C-u>%s"):format(tag, indentation(bufnr, width))
  )
end

function M.attach(bufnr)
  if attached[bufnr] or next(current_mapping(bufnr)) ~= nil then
    return false
  end

  vim.keymap.set("i", "<CR>", function()
    return M.enter(bufnr)
  end, {
    buffer = bufnr,
    desc = mapping_description,
    expr = true,
    replace_keycodes = false,
  })
  attached[bufnr] = true
  return true
end

function M.detach(bufnr)
  if not attached[bufnr] then
    return
  end
  local mapping = current_mapping(bufnr)
  if mapping.desc == mapping_description then
    pcall(vim.keymap.del, "i", "<CR>", { buffer = bufnr })
  end
  attached[bufnr] = nil
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("argiope_authoring", { clear = true }),
  callback = function(event)
    attached[event.buf] = nil
  end,
})

return M
