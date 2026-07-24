local model = require("argiope.model")

local M = {}
local namespace = vim.api.nvim_create_namespace("argiope.html")
local attached = {}
local pending = {}
local spans_by_buffer = {}

local function replace_bytes(text, start_col, end_col, replacement)
  if end_col <= start_col then
    return text
  end
  return text:sub(1, start_col)
    .. string.rep(replacement, end_col - start_col)
    .. text:sub(end_col + 1)
end

local function template_content(bufnr, template)
  local start_row, start_col, end_row, end_col = unpack(template.range)
  local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
  local lines = {}
  local mappings = {}
  local exclusions = {}

  for index, buffer_line in ipairs(buffer_lines) do
    local row = start_row + index - 1
    local content_start = row == start_row and start_col + 1 or 0
    local content_end = #buffer_line
    if row == end_row then
      content_end = template.closed and math.max(end_col - 1, content_start) or end_col
    end

    lines[index] = buffer_line:sub(content_start + 1, content_end)
    mappings[index] = {
      row = row,
      start_col = content_start,
    }
    exclusions[index] = {}
  end

  -- Included ranges make the injected HTML parser skip JavaScript
  -- substitutions entirely. In an unquoted attribute, that turns
  -- `id=${id} name=${name}` into the equivalent of `id= name=`, so the next
  -- attribute name is parsed as the previous value. Replacing substitutions
  -- with same-width text gives a temporary parser valid HTML while preserving
  -- exact source coordinates. The placeholder ranges are excluded again when
  -- captures are mapped back to the buffer.
  for _, child in ipairs(template.node:named_children()) do
    if child:type() == "template_substitution" then
      local sub_start_row, sub_start_col, sub_end_row, sub_end_col = child:range()
      for row = sub_start_row, sub_end_row do
        local index = row - start_row + 1
        local mapping = mappings[index]
        local line = lines[index]
        if mapping and line then
          local actual_start = row == sub_start_row and sub_start_col or mapping.start_col
          local actual_end = row == sub_end_row and sub_end_col or mapping.start_col + #line
          local local_start = math.max(actual_start - mapping.start_col, 0)
          local local_end = math.min(actual_end - mapping.start_col, #line)
          if local_end > local_start then
            lines[index] = replace_bytes(line, local_start, local_end, "x")
            table.insert(exclusions[index], { local_start, local_end })
          end
        end
      end
    end
  end

  return {
    text = table.concat(lines, "\n"),
    lines = lines,
    mappings = mappings,
    exclusions = exclusions,
  }
end

local function subtract_ranges(start_col, end_col, exclusions)
  local ranges = { { start_col, end_col } }
  for _, exclusion in ipairs(exclusions or {}) do
    local next_ranges = {}
    for _, range in ipairs(ranges) do
      if exclusion[2] <= range[1] or exclusion[1] >= range[2] then
        table.insert(next_ranges, range)
      else
        if exclusion[1] > range[1] then
          table.insert(next_ranges, { range[1], exclusion[1] })
        end
        if exclusion[2] < range[2] then
          table.insert(next_ranges, { exclusion[2], range[2] })
        end
      end
    end
    ranges = next_ranges
  end
  return ranges
end

local function capture_priority(metadata, capture_id)
  local priority = tonumber(metadata.priority or metadata[capture_id] and metadata[capture_id].priority)
    or vim.hl.priorities.treesitter

  -- Normalized captures must beat the JavaScript string-fragment capture and
  -- any malformed captures from the ordinary included-range HTML tree.
  return priority + 100
end

local function add_capture_spans(
  spans,
  document,
  language,
  capture,
  node,
  metadata,
  capture_id
)
  if capture:sub(1, 1) == "_" then
    return
  end

  local start_row, start_col, _, end_row, end_col =
    unpack(vim.treesitter.get_range(node, document.text, metadata[capture_id]))
  local final_row = end_col == 0 and end_row - 1 or end_row
  local highlight_language = language == "javascript" and "argiope_javascript"
    or language
  local group = ("@%s.%s"):format(capture, highlight_language)
  local priority = capture_priority(metadata, capture_id)

  for row = start_row, final_row do
    local line = document.lines[row + 1]
    local mapping = document.mappings[row + 1]
    if line and mapping then
      local range_start = row == start_row and start_col or 0
      local range_end = row == end_row and end_col or #line
      range_end = math.min(range_end, #line)

      for _, range in ipairs(
        subtract_ranges(range_start, range_end, document.exclusions[row + 1])
      ) do
        if range[2] > range[1] then
          local buffer_row = mapping.row
          spans[buffer_row] = spans[buffer_row] or {}
          table.insert(spans[buffer_row], {
            start_col = mapping.start_col + range[1],
            end_col = mapping.start_col + range[2],
            group = group,
            priority = priority,
          })
        end
      end
    end
  end
end

local function parse_template(spans, document)
  local ok, parser = pcall(vim.treesitter.get_string_parser, document.text, "html", {
    injections = {
      javascript = "",
    },
  })
  if not ok or not parser then
    return
  end

  local parsed = pcall(parser.parse, parser, true)
  if not parsed then
    return
  end

  parser:for_each_tree(function(tree, language_tree)
    local language = language_tree:lang()
    if language ~= "html" and language ~= "css" and language ~= "javascript" then
      return
    end

    local query = vim.treesitter.query.get(language, "highlights")
    if not query then
      return
    end

    for capture_id, node, metadata in query:iter_captures(tree:root(), document.text, 0, -1) do
      add_capture_spans(
        spans,
        document,
        language,
        query.captures[capture_id],
        node,
        metadata or {},
        capture_id
      )
    end
  end)
end

local function rebuild(bufnr)
  if not attached[bufnr] or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local spans = {}
  local templates = model.templates(bufnr)
  if templates then
    for _, template in ipairs(templates) do
      if template.registered and template.language == "html" then
        parse_template(spans, template_content(bufnr, template))
      end
    end
  end

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  for row, row_spans in pairs(spans) do
    for _, span in ipairs(row_spans) do
      vim.api.nvim_buf_set_extmark(bufnr, namespace, row, span.start_col, {
        end_row = row,
        end_col = span.end_col,
        hl_group = span.group,
        priority = span.priority,
      })
    end
  end
  spans_by_buffer[bufnr] = spans
  return true
end

local function schedule_rebuild(bufnr)
  if pending[bufnr] then
    return
  end
  pending[bufnr] = true
  vim.schedule(function()
    pending[bufnr] = nil
    if rebuild(bufnr) then
      vim.cmd.redraw()
    end
  end)
end

local group = vim.api.nvim_create_augroup("argiope_html", { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
  group = group,
  callback = function(event)
    if attached[event.buf] then
      schedule_rebuild(event.buf)
    end
  end,
  desc = "Refresh normalized HTML template highlighting",
})
vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(event)
    attached[event.buf] = nil
    pending[event.buf] = nil
    spans_by_buffer[event.buf] = nil
  end,
})

function M.attach(bufnr)
  attached[bufnr] = true
  return rebuild(bufnr)
end

function M.detach(bufnr)
  attached[bufnr] = nil
  pending[bufnr] = nil
  spans_by_buffer[bufnr] = nil
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end
end

function M._captures_at(bufnr, row, col)
  local captures = {}
  for _, span in ipairs((spans_by_buffer[bufnr] or {})[row] or {}) do
    if col >= span.start_col and col < span.end_col then
      table.insert(captures, vim.deepcopy(span))
    end
  end
  return captures
end

return M
