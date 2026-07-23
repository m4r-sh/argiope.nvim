local config = require("argiope.config")
local model = require("argiope.model")

local M = {}

M.expression = "v:lua.require'argiope.indent'.getindent(v:lnum)"

local function shiftwidth(bufnr)
  local configured = config.get().indent.shiftwidth
  if configured > 0 then
    return configured
  end

  local value = vim.bo[bufnr].shiftwidth
  if value == 0 then
    value = vim.bo[bufnr].tabstop
  end
  return value
end

local function fallback_indent(bufnr, lnum)
  local expression = vim.b[bufnr].argiope_previous_indentexpr
  if expression and expression ~= "" and expression ~= M.expression then
    local ok, value = pcall(vim.api.nvim_buf_call, bufnr, function()
      return vim.api.nvim_eval(expression)
    end)
    if ok and type(value) == "number" then
      return value
    end
  end

  local previous = vim.fn.prevnonblank(lnum - 1)
  return previous > 0 and vim.fn.indent(previous) or 0
end

local ignored_injected_languages = {
  comment = true,
  javadoc = true,
  jsdoc = true,
  luadoc = true,
  phpdoc = true,
}

local function injected_root_at(parser, row, col)
  local selected
  parser:for_each_tree(function(tree, language_tree)
    local language = language_tree:lang()
    if language == "javascript" or ignored_injected_languages[language] then
      return
    end

    local root = tree:root()
    if vim.treesitter.is_in_node_range(root, row, col) then
      if not selected or root:byte_length() < selected:byte_length() then
        selected = root
      end
    end
  end)
  return selected
end

local function embedded_indent(bufnr, lnum, content_base)
  local ok, treesitter_indent = pcall(require, "nvim-treesitter.indent")
  if not ok then
    return nil
  end

  local parser = model.parser(bufnr)
  if not parser then
    return nil
  end

  local row = lnum - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local leading = line:match("^%s*") or ""
  local parsed = pcall(parser.parse, parser, { math.max(row - 1, 0), row + 2 })
  if not parsed then
    return nil
  end

  local root = injected_root_at(parser, row, #leading)
  if not root then
    return nil
  end

  local root_row = root:start()
  local succeeded, result = pcall(vim.api.nvim_buf_call, bufnr, function()
    return {
      value = treesitter_indent.get_indent(lnum),
      root_indent = vim.fn.indent(root_row + 1),
    }
  end)
  if not succeeded or type(result.value) ~= "number" or result.value < 0 then
    return nil
  end

  local relative = math.max(result.value - result.root_indent, 0)
  return content_base + relative
end

local function embedded_content_base(bufnr, context, fallback)
  local current = context.template
  local first_same_language
  local nested_same_language = 0

  -- injection.combined places nested templates of the same language in one
  -- embedded tree. Anchor that tree once, then add only the template nesting
  -- offsets; using the inner tag's visual indent would count the outer
  -- language structure twice.
  for _, template in ipairs(context.stack or {}) do
    if template.registered and template.language == current.language then
      first_same_language = first_same_language or template
      if template.node:equal(current.node) then
        break
      end
      nested_same_language = nested_same_language + 1
    end
  end

  if not first_same_language or nested_same_language == 0 then
    return fallback
  end

  local start_row = first_same_language.range[1]
  return vim.fn.indent(start_row + 1) + shiftwidth(bufnr) * (nested_same_language + 1)
end

local function template_indent(bufnr, lnum, context)
  local row = lnum - 1
  local template = context.template
  local start_row, _, end_row = unpack(template.range)
  local base = vim.fn.indent(start_row + 1)
  local content = base + shiftwidth(bufnr)
  local embedded_content = embedded_content_base(bufnr, context, content)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local trimmed = line:match("^%s*(.*)$") or ""

  if row == end_row and trimmed:sub(1, 1) == "`" then
    -- When <CR> splits an empty pair, the closing delimiter is temporarily on
    -- the new line before any content is inserted. Indent that insertion point
    -- as content; a subsequent <CR> reparses the delimiter onto its own line
    -- and aligns it with the tag.
    if row == start_row + 1 and vim.fn.mode(1):sub(1, 1) == "i" then
      return content
    end
    return base
  end

  local interpolation = context.interpolation
  if interpolation then
    local interpolation_start, _, interpolation_end = interpolation:range()
    if row == interpolation_start or row == interpolation_end then
      local language_indent = embedded_indent(bufnr, lnum, embedded_content)
      if language_indent ~= nil then
        return language_indent
      end
      return content
    end
    return content + shiftwidth(bufnr)
  end

  local language_indent = embedded_indent(bufnr, lnum, embedded_content)
  if language_indent ~= nil then
    return language_indent
  end

  return content
end

function M.get(bufnr, lnum)
  bufnr = bufnr or 0
  local options = config.get()
  if not options.enabled or not options.indent.enabled then
    return fallback_indent(bufnr, lnum)
  end

  local context = model.context_for_line(bufnr, lnum)
  if context and context.template then
    return template_indent(bufnr, lnum, context)
  end

  return fallback_indent(bufnr, lnum)
end

function M.getindent(lnum)
  return M.get(0, lnum)
end

return M
