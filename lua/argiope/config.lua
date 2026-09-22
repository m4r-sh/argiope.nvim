local M = {}

M.defaults = {
  enabled = true,
  filetypes = {
    css = true,
    glsl = true,
    html = true,
    javascript = true,
    markdown = true,
    wgsl = true,
  },
  tags = {
    css = "css",
    glsl = "glsl",
    html = "html",
    md = "markdown",
    ["raw.js"] = "javascript",
    svg = "svg",
    wgsl = "wgsl",
  },
  indent = {
    enabled = true,
    shiftwidth = 2,
    expandtab = true,
  },
  authoring = {
    auto_close_tags = true,
  },
  highlight = {
    enabled = true,
    auto_start = true,
    languages = {},
  },
  join = {
    enabled = true,
  },
  theme = {
    variant = "aurantia",
    overlay = false,
    definitions = {},
  },
}

local options = vim.deepcopy(M.defaults)
local supported_languages = {
  css = true,
  glsl = true,
  html = true,
  javascript = true,
  markdown = true,
  svg = true,
  wgsl = true,
}
local filetype_languages = {
  css = "css",
  glsl = "glsl",
  html = "html",
  javascript = "javascript",
  markdown = "markdown",
  wgsl = "wgsl",
}
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
  for tag, language in pairs(opts.tags) do
    if tag:gsub("%s+", "") == "" then
      error("argiope: tag names must not be empty")
    end
    if not supported_languages[language] then
      error(
        ("argiope: tags.%s must map to css, glsl, html, javascript, markdown, svg, or wgsl (got %q)"):format(
          tag,
          language
        )
      )
    end
  end
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
  if type(opts.highlight.auto_start) ~= "boolean" then
    error("argiope: highlight.auto_start must be a boolean")
  end
  if type(opts.highlight.languages) ~= "table" then
    error("argiope: highlight.languages must be a table")
  end
  for language, assignment in pairs(opts.highlight.languages) do
    require("argiope.theme").validate_language(language, assignment, opts.theme.variant)
  end
  if type(opts.theme.overlay) ~= "boolean" then
    error("argiope: theme.overlay must be a boolean")
  end
  if
    type(opts.authoring) ~= "table"
    or type(opts.authoring.auto_close_tags) ~= "boolean"
  then
    error("argiope: authoring.auto_close_tags must be a boolean")
  end
  if type(opts.join) ~= "table" or type(opts.join.enabled) ~= "boolean" then
    error("argiope: join.enabled must be a boolean")
  end
  if
    type(opts.theme) ~= "table"
    or type(opts.theme.variant) ~= "string"
    or not require("argiope.palette").profile(opts.theme.variant)
  then
    error("argiope: unknown theme.variant")
  end
  if type(opts.theme.definitions) ~= "table" then
    error("argiope: theme.definitions must be a table")
  end
end

function M.setup(user_options)
  if user_options ~= nil and type(user_options) ~= "table" then
    error("argiope: setup options must be a table")
  end

  local resolved = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_options or {})
  local themes = require("argiope.palette")
  local ok, err = pcall(function()
    themes.reset(resolved.theme.definitions)
    validate(resolved)
  end)
  if not ok then
    themes.reset(options.theme.definitions)
    error(err, 0)
  end
  options = resolved
  return resolved
end

function M.get()
  return options
end

function M.filetype_enabled(filetype)
  return options.enabled and filetype ~= "" and options.filetypes[filetype] ~= false
    and (options.filetypes[filetype] == true or options.highlight.auto_start)
end

function M.parser_language(filetype)
  return filetype_languages[filetype] or vim.treesitter.language.get_lang(filetype)
end

return M
