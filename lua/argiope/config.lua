local M = {}

M.defaults = {
  enabled = true,
  filetypes = {
    javascript = true,
  },
  tags = {
    css = "css",
    html = "html",
    md = "markdown",
    svg = "svg",
  },
  indent = {
    enabled = true,
    shiftwidth = 2,
    expandtab = true,
  },
  highlight = {
    enabled = true,
  },
  palettes = {
    css = "green",
    html = "cyan",
    javascript = "gold2",
    markdown = "violet",
    svg = "blue",
  },
}

local options = vim.deepcopy(M.defaults)

local function validate_string_map(name, value)
  if type(value) ~= "table" then
    error(("argiope: %s must be a table"):format(name))
  end

  for key, entry in pairs(value) do
    if type(key) ~= "string" or type(entry) ~= "string" then
      error(("argiope: %s must map strings to strings"):format(name))
    end
  end
end

local function validate(opts)
  if type(opts.enabled) ~= "boolean" then
    error("argiope: enabled must be a boolean")
  end

  if type(opts.filetypes) ~= "table" then
    error("argiope: filetypes must be a table")
  end
  for filetype, enabled in pairs(opts.filetypes) do
    if type(filetype) ~= "string" or type(enabled) ~= "boolean" then
      error("argiope: filetypes must map strings to booleans")
    end
  end

  validate_string_map("tags", opts.tags)
  validate_string_map("palettes", opts.palettes)

  if type(opts.indent) ~= "table" or type(opts.indent.enabled) ~= "boolean" then
    error("argiope: indent.enabled must be a boolean")
  end
  if type(opts.indent.expandtab) ~= "boolean" then
    error("argiope: indent.expandtab must be a boolean")
  end
  if
    type(opts.indent.shiftwidth) ~= "number"
    or opts.indent.shiftwidth < 0
    or opts.indent.shiftwidth % 1 ~= 0
  then
    error("argiope: indent.shiftwidth must be a non-negative integer")
  end

  if type(opts.highlight) ~= "table" or type(opts.highlight.enabled) ~= "boolean" then
    error("argiope: highlight.enabled must be a boolean")
  end
end

function M.setup(user_options)
  if user_options ~= nil and type(user_options) ~= "table" then
    error("argiope: setup options must be a table")
  end

  options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_options or {})
  validate(options)
  return options
end

function M.get()
  return options
end

function M.filetype_enabled(filetype)
  return options.enabled and options.filetypes[filetype] == true
end

return M
