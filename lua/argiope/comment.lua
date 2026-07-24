local M = {}

local wrappers = {
  "^(%s*)%${''/%* (.-) %*/}%s*$",
  '^(%s*)%${""/%* (.-) %*/}%s*$',
}

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

function M.toggle_interpolation(bufnr, line_start, line_end)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    error("argiope: cannot toggle interpolation comments in an invalid buffer")
  end
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

return M
