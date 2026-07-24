local config = require("argiope.config")
local registry = require("argiope.registry")
local indent = require("argiope.indent")
local highlight = require("argiope.highlight")
local injections = require("argiope.injections")

local M = {}
local group

registry.reset(config.get().tags)

local function supports_neovim()
  return vim.fn.has("nvim-0.12") == 1
end

local function ensure_indentkey(value, key)
  local keys = vim.split(value, ",", { plain = true, trimempty = true })
  if not vim.tbl_contains(keys, key) then
    table.insert(keys, key)
  end
  return table.concat(keys, ",")
end

local function save_indent_options(bufnr)
  if vim.b[bufnr].argiope_previous_indent_options then
    return
  end

  vim.b[bufnr].argiope_previous_indent_options = {
    autoindent = vim.bo[bufnr].autoindent,
    expandtab = vim.bo[bufnr].expandtab,
    indentexpr = vim.bo[bufnr].indentexpr,
    indentkeys = vim.bo[bufnr].indentkeys,
    shiftwidth = vim.bo[bufnr].shiftwidth,
    softtabstop = vim.bo[bufnr].softtabstop,
  }
end

local function restore_indent_options(bufnr)
  local previous = vim.b[bufnr].argiope_previous_indent_options
  if not previous then
    return
  end

  vim.bo[bufnr].autoindent = previous.autoindent
  vim.bo[bufnr].expandtab = previous.expandtab
  vim.bo[bufnr].indentexpr = previous.indentexpr
  vim.bo[bufnr].indentkeys = previous.indentkeys
  vim.bo[bufnr].shiftwidth = previous.shiftwidth
  vim.bo[bufnr].softtabstop = previous.softtabstop
  vim.b[bufnr].argiope_previous_indent_options = nil
end

local function ensure_commands()
  vim.api.nvim_create_user_command("ArgiopeThemeToggle", function()
    local mode = M.toggle_theme()
    vim.notify(("Argiope theme: %s"):format(mode), vim.log.levels.INFO)
  end, {
    desc = "Toggle Argiope JavaScript between monochrome and Dracula colors",
    force = true,
  })
end

function M.get_theme_mode()
  return require("argiope.theme").get_mode()
end

function M.set_theme_mode(mode)
  return require("argiope.theme").set_mode(mode)
end

function M.toggle_theme()
  return require("argiope.theme").toggle()
end

function M.toggle_interpolation_comment(bufnr, line_start, line_end)
  return require("argiope.comment").toggle_interpolation(bufnr, line_start, line_end)
end

function M.toggle_interpolation_selection(bufnr)
  return require("argiope.comment").toggle_selection(
    bufnr,
    vim.fn.getpos("v"),
    vim.fn.getpos("."),
    vim.fn.mode()
  )
end

function M.attach(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    return false, "invalid buffer"
  end
  if not supports_neovim() then
    return false, "argiope requires Neovim 0.12 or newer"
  end
  local options = config.get()
  if
    not config.filetype_enabled(vim.bo[bufnr].filetype)
    or (not options.indent.enabled and not options.highlight.enabled)
  then
    return false, "disabled for this buffer"
  end

  local parser, parser_error = vim.treesitter.get_parser(bufnr, "javascript", { error = false })
  if not parser then
    vim.b[bufnr].argiope_parser_error = parser_error or "JavaScript parser unavailable"
    return false, vim.b[bufnr].argiope_parser_error
  end

  local parsed, parse_error = pcall(parser.parse, parser)
  if not parsed then
    vim.b[bufnr].argiope_parser_error = parse_error
    return false, parse_error
  end

  if options.highlight.enabled then
    local highlighted, highlight_error = highlight.attach(bufnr)
    if not highlighted then
      vim.b[bufnr].argiope_parser_error = highlight_error
      return false, highlight_error
    end
  else
    highlight.detach(bufnr)
  end

  if options.indent.enabled then
    save_indent_options(bufnr)

    local indent_options = options.indent
    if indent_options.shiftwidth > 0 then
      vim.bo[bufnr].shiftwidth = indent_options.shiftwidth
      vim.bo[bufnr].softtabstop = indent_options.shiftwidth
    end
    vim.bo[bufnr].expandtab = indent_options.expandtab
    vim.bo[bufnr].indentexpr = indent.expression
    local keys = vim.bo[bufnr].indentkeys
    keys = ensure_indentkey(keys, "o")
    keys = ensure_indentkey(keys, "O")
    keys = ensure_indentkey(keys, "0}")
    vim.bo[bufnr].indentkeys = keys
    vim.bo[bufnr].autoindent = true
  else
    restore_indent_options(bufnr)
  end

  vim.b[bufnr].argiope_attached = true
  vim.b[bufnr].argiope_parser_error = nil
  return true
end

function M.detach(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  restore_indent_options(bufnr)
  highlight.detach(bufnr)
  vim.b[bufnr].argiope_attached = nil
  vim.b[bufnr].argiope_parser_error = nil
end

function M._load()
  if not supports_neovim() then
    return
  end

  ensure_commands()
  injections.install()

  if group then
    pcall(vim.api.nvim_del_augroup_by_id, group)
  end
  group = vim.api.nvim_create_augroup("argiope", { clear = true })

  local patterns = {}
  for filetype, enabled in pairs(config.get().filetypes) do
    if enabled then
      table.insert(patterns, filetype)
    end
  end

  if #patterns > 0 then
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = patterns,
      callback = function(event)
        M.attach(event.buf)
      end,
      desc = "Attach argiope tagged-template support",
    })
  end
end

function M.setup(options)
  if not supports_neovim() then
    error("argiope requires Neovim 0.12 or newer")
  end

  local resolved = config.setup(options)
  injections.install()
  registry.reset(resolved.tags)
  M._load()

  if vim.g.colors_name == "argiope" then
    require("argiope.theme").apply()
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      if
        config.filetype_enabled(vim.bo[bufnr].filetype)
        and (resolved.indent.enabled or resolved.highlight.enabled)
      then
        M.attach(bufnr)
      elseif vim.b[bufnr].argiope_attached then
        M.detach(bufnr)
      end
    end
  end

  return resolved
end

return M
