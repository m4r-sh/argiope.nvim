local registry = require("argiope.registry")

local M = {}

local function parser_for(bufnr)
  local parser, err = vim.treesitter.get_parser(bufnr, "javascript", { error = false })
  if not parser then
    return nil, err or "JavaScript Tree-sitter parser is unavailable"
  end

  local ok, trees = pcall(parser.parse, parser)
  if not ok or not trees or not trees[1] then
    return nil, ok and "JavaScript Tree-sitter parser returned no tree" or trees
  end

  return parser, trees[1]:root()
end

local function contains(node, row, col)
  local start_row, start_col, end_row, end_col = node:range()
  if row < start_row or row > end_row then
    return false
  end
  if row == start_row and col < start_col then
    return false
  end
  if row == end_row and col > end_col then
    return false
  end
  return true
end

-- Tree-sitter ranges are end-exclusive, but an incomplete template often ends
-- exactly at an empty line's (row, 0). Treating the endpoint as addressable is
-- important for indentation while the user is still typing.
local function deepest_named_node(node, row, col)
  local match = node
  for _, child in ipairs(node:named_children()) do
    if contains(child, row, col) then
      match = deepest_named_node(child, row, col)
    end
  end
  return match
end

local function template_from_node(bufnr, node)
  if not node or node:type() ~= "template_string" then
    return nil
  end

  local template_text = vim.treesitter.get_node_text(node, bufnr)
  local start_row, start_col, end_row, end_col = node:range()
  local template = {
    node = node,
    tagged = false,
    registered = false,
    closed = #template_text >= 2 and template_text:sub(-1) == "`",
    range = { start_row, start_col, end_row, end_col },
  }

  local call = node:parent()
  if not call or call:type() ~= "call_expression" then
    return template
  end

  local is_argument = false
  for _, argument in ipairs(call:field("arguments")) do
    if argument:equal(node) then
      is_argument = true
      break
    end
  end
  if not is_argument then
    return template
  end

  local tag_node = call:field("function")[1]
  if not tag_node then
    return template
  end

  local tag = vim.treesitter.get_node_text(tag_node, bufnr):gsub("%s+", "")
  local language = registry.resolve(tag)
  template.call = call
  template.tag_node = tag_node
  template.tag = tag
  template.language = language
  template.tagged = true
  template.registered = language ~= nil
  return template
end

function M.parser(bufnr)
  bufnr = bufnr or 0
  local parser, root_or_error = parser_for(bufnr)
  if not parser then
    return nil, root_or_error
  end
  return parser
end

function M.templates(bufnr)
  bufnr = bufnr or 0
  local parser, root_or_error = parser_for(bufnr)
  if not parser then
    return nil, root_or_error
  end
  local root = root_or_error
  local templates = {}

  local function visit(node)
    if node:type() == "template_string" then
      local template = template_from_node(bufnr, node)
      if template and template.tagged then
        table.insert(templates, template)
      end
    end
    for _, child in ipairs(node:named_children()) do
      visit(child)
    end
  end

  visit(root)
  return templates
end

local function context_from_root(bufnr, root, row, col)
  local node = deepest_named_node(root, row, col)
  local stack = {}
  local pending_interpolation
  local current = node

  while current do
    if current:type() == "template_substitution" then
      pending_interpolation = current
    elseif current:type() == "template_string" then
      local template = template_from_node(bufnr, current)
      if template then
        template.interpolation = pending_interpolation
        table.insert(stack, 1, template)
      end
      pending_interpolation = nil
    end
    current = current:parent()
  end

  local nearest = stack[#stack]
  local owned = nearest and nearest.registered and nearest or nil

  return {
    node = node,
    stack = stack,
    template = owned,
    interpolation = owned and owned.interpolation or nil,
    blocked_by = nearest and not nearest.registered and nearest or nil,
  }
end

function M.context_at(bufnr, row, col)
  bufnr = bufnr or 0
  col = col or 0

  local parser, root_or_error = parser_for(bufnr)
  if not parser then
    return nil, root_or_error
  end

  return context_from_root(bufnr, root_or_error, row, col)
end

function M.context_for_line(bufnr, lnum)
  bufnr = bufnr or 0
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local leading = line:match("^%s*") or ""
  return M.context_at(bufnr, lnum - 1, #leading)
end

return M
