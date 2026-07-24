local M = {}

local interpolation_prefixes = {
  "${''/* ",
  '${""/* ',
}
local interpolation_suffix = " */}"
local expression_prefixes = {
  "''/* ",
  '""/* ',
}
local expression_suffix = " */"

local wrappers = {
  "^(%s*)%${''/%* (.-) %*/}%s*$",
  '^(%s*)%${""/%* (.-) %*/}%s*$',
}

local function text_lines(text)
  return vim.split(text, "\n", { plain = true, trimempty = false })
end

local function unwrapped_text(text)
  for _, prefix in ipairs(interpolation_prefixes) do
    if
      text:sub(1, #prefix) == prefix
      and text:sub(-#interpolation_suffix) == interpolation_suffix
    then
      return text:sub(#prefix + 1, -#interpolation_suffix - 1)
    end
  end
end

local function unwrapped_expression(text)
  for _, prefix in ipairs(expression_prefixes) do
    if
      text:sub(1, #prefix) == prefix
      and text:sub(-#expression_suffix) == expression_suffix
    then
      return text:sub(#prefix + 1, -#expression_suffix - 1)
    end
  end
end

local function no_op_expression(text)
  return expression_prefixes[1] .. text .. expression_suffix
end

local function is_javascript_expression(text)
  if text:match("^%s*$") then
    return false
  end

  local ok, parser = pcall(
    vim.treesitter.get_string_parser,
    "const __argiope_expression = (" .. text .. ")",
    "javascript"
  )
  if not ok or not parser then
    return false
  end

  local parsed, trees = pcall(parser.parse, parser, true)
  return parsed
    and trees
    and trees[1]
    and not trees[1]:root():has_error()
end

local function uncommented(line)
  for _, pattern in ipairs(wrappers) do
    local indent, body = line:match(pattern)
    if body ~= nil then
      return indent .. body
    end
  end
end

local function commented(line)
  if line:match("^%s*$") or uncommented(line) then
    return line
  end

  local indent, body = line:match("^(%s*)(.*)$")
  return ("%s${''/* %s */}"):format(indent, body)
end

local function validate_buffer(bufnr)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    error("argiope: cannot toggle interpolation comments in an invalid buffer")
  end
  return bufnr
end

local function selected_text(bufnr, start_row, start_col, end_row, end_col)
  return table.concat(
    vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {}),
    "\n"
  )
end

local function replace_text(bufnr, start_row, start_col, end_row, end_col, text)
  vim.api.nvim_buf_set_text(
    bufnr,
    start_row,
    start_col,
    end_row,
    end_col,
    text_lines(text)
  )
end

local function surrounding_wrapper(
  bufnr,
  start_row,
  start_col,
  end_row,
  end_col
)
  local start_line =
    vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
  local end_line =
    vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""

  for _, prefix in ipairs(interpolation_prefixes) do
    local prefix_start = start_col - #prefix
    if
      prefix_start >= 0
      and start_line:sub(prefix_start + 1, start_col) == prefix
      and end_line:sub(end_col + 1, end_col + #interpolation_suffix)
        == interpolation_suffix
    then
      return prefix_start, end_col + #interpolation_suffix
    end
  end
end

local function toggle_exact_interpolation(
  bufnr,
  start_row,
  start_col,
  end_row,
  end_col,
  text
)
  if text:sub(1, 2) == "${" and text:sub(-1) == "}" then
    local expression = text:sub(3, -2)
    local original = unwrapped_expression(expression)
    if original ~= nil and not is_javascript_expression(original) then
      replace_text(bufnr, start_row, start_col, end_row, end_col, original)
      return true
    end
    replace_text(
      bufnr,
      start_row,
      start_col,
      end_row,
      end_col,
      "${" .. (original or no_op_expression(expression)) .. "}"
    )
    return true
  end

  local start_line =
    vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1] or ""
  local end_line =
    vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
  if
    start_col >= 2
    and start_line:sub(start_col - 1, start_col) == "${"
    and end_line:sub(end_col + 1, end_col + 1) == "}"
  then
    local original = unwrapped_expression(text)
    if original ~= nil and not is_javascript_expression(original) then
      replace_text(
        bufnr,
        start_row,
        start_col - 2,
        end_row,
        end_col + 1,
        original
      )
      return true
    end
    replace_text(
      bufnr,
      start_row,
      start_col,
      end_row,
      end_col,
      original or no_op_expression(text)
    )
    return true
  end

  return false
end

local function toggle_range(bufnr, start_row, start_col, end_row, end_col)
  local text = selected_text(bufnr, start_row, start_col, end_row, end_col)
  if text == "" then
    return false
  end

  if
    toggle_exact_interpolation(
      bufnr,
      start_row,
      start_col,
      end_row,
      end_col,
      text
    )
  then
    return true
  end

  local body = unwrapped_text(text)
  if body ~= nil then
    replace_text(bufnr, start_row, start_col, end_row, end_col, body)
    return true
  end

  local outer_start, outer_end =
    surrounding_wrapper(bufnr, start_row, start_col, end_row, end_col)
  if outer_start then
    replace_text(bufnr, start_row, outer_start, end_row, outer_end, text)
    return true
  end

  replace_text(
    bufnr,
    start_row,
    start_col,
    end_row,
    end_col,
    interpolation_prefixes[1] .. text .. interpolation_suffix
  )
  return true
end

local function end_col_exclusive(bufnr, position)
  local row = position[2] - 1
  local col = position[3]
  if col <= 0 then
    return 0
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  if col > #line then
    return #line
  end

  local character = vim.fn.strcharpart(line:sub(col), 0, 1)
  return col - 1 + #character
end

local function visual_regions(bufnr, start_position, end_position, visual_mode)
  return vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.getregionpos(start_position, end_position, {
      type = visual_mode,
      exclusive = vim.o.selection == "exclusive",
      eol = true,
    })
  end)
end

function M.toggle_interpolation(bufnr, line_start, line_end)
  bufnr = validate_buffer(bufnr)
  if
    type(line_start) ~= "number"
    or type(line_end) ~= "number"
    or line_start % 1 ~= 0
    or line_end % 1 ~= 0
  then
    error("argiope: interpolation comment range must use integer line numbers")
  end

  line_start, line_end = math.min(line_start, line_end), math.max(line_start, line_end)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_start < 1 or line_end > line_count then
    error("argiope: interpolation comment range is outside the buffer")
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, line_start - 1, line_end, false)
  local has_content = false
  local all_commented = true
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") then
      has_content = true
      all_commented = all_commented and uncommented(line) ~= nil
    end
  end
  if not has_content then
    return false
  end

  for index, line in ipairs(lines) do
    if not line:match("^%s*$") then
      if all_commented then
        lines[index] = assert(uncommented(line))
      else
        lines[index] = commented(line)
      end
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, line_start - 1, line_end, false, lines)
  return true
end

function M.toggle_selection(bufnr, start_position, end_position, visual_mode)
  bufnr = validate_buffer(bufnr)
  if type(start_position) ~= "table" or type(end_position) ~= "table" then
    error("argiope: interpolation selection requires two buffer positions")
  end

  if visual_mode == "V" then
    return M.toggle_interpolation(bufnr, start_position[2], end_position[2])
  end
  if visual_mode ~= "v" and visual_mode ~= "\22" then
    error("argiope: interpolation selection must be characterwise, linewise, or blockwise")
  end

  local regions = visual_regions(bufnr, start_position, end_position, visual_mode)
  if #regions == 0 then
    return false
  end

  if visual_mode == "v" then
    local first = regions[1][1]
    local last = regions[#regions][2]
    return toggle_range(
      bufnr,
      first[2] - 1,
      math.max(first[3] - 1, 0),
      last[2] - 1,
      end_col_exclusive(bufnr, last)
    )
  end

  local changed = false
  for index = #regions, 1, -1 do
    local first, last = unpack(regions[index])
    changed = toggle_range(
      bufnr,
      first[2] - 1,
      math.max(first[3] - 1, 0),
      last[2] - 1,
      end_col_exclusive(bufnr, last)
    ) or changed
  end
  return changed
end

return M
