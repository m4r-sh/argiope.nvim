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
    ["raw.js"] = "javascript",
  },
  indent = {
    enabled = true,
    shiftwidth = 2,
    expandtab = true,
  },
  highlight = {
    enabled = true,
  },
  join = {
    enabled = true,
  },
  theme = {
    variant = "aurantia",
    palettes = {},
  },
  palettes = {},
}

local options = vim.deepcopy(M.defaults)
local supported_languages = {
  css = true,
  html = true,
  javascript = true,
  markdown = true,
}
local supported_filetypes = {
  javascript = true,
}
local supported_palettes = {
  beige = true,
  blue = true,
  blush = true,
  ember = true,
  cyan = true,
  gold = true,
  gold2 = true,
  gray = true,
  green = true,
  indigo = true,
  pink = true,
  slate = true,
  violet = true,
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

local function validate_palette_map(name, value)
  validate_string_map(name, value)
  for language, palette_name in pairs(value) do
    if not supported_palettes[palette_name] then
      error(
        ("argiope: %s.%s uses unknown palette %q"):format(
          name,
          language,
          palette_name
        )
      )
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
    if enabled and not supported_filetypes[filetype] then
      error(("argiope: unsupported filetype %q (only javascript is supported)"):format(filetype))
    end
  end

  validate_string_map("tags", opts.tags)
  validate_palette_map("palettes", opts.palettes)
  for tag, language in pairs(opts.tags) do
    if tag:gsub("%s+", "") == "" then
      error("argiope: tag names must not be empty")
    end
    if not supported_languages[language] then
      error(
        ("argiope: tags.%s must map to css, html, javascript, or markdown (got %q)"):format(
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
  if type(opts.theme.palettes) ~= "table" then
    error("argiope: theme.palettes must be a table")
  end
  for variant, palettes in pairs(opts.theme.palettes) do
    if not require("argiope.palette").profile(variant) then
      error(("argiope: theme.palettes uses unknown variant %q"):format(variant))
    end
    validate_palette_map(("theme.palettes.%s"):format(variant), palettes)
  end
end

function M.setup(user_options)
  if user_options ~= nil and type(user_options) ~= "table" then
    error("argiope: setup options must be a table")
  end

  local resolved = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_options or {})
  validate(resolved)
  options = resolved
  return resolved
end

function M.get()
  return options
end

function M.get_palettes(variant)
  local profile = assert(require("argiope.palette").profile(variant))
  return vim.tbl_deep_extend(
    "force",
    vim.deepcopy(profile.palettes),
    options.palettes,
    options.theme.palettes[variant] or {}
  )
end

function M.filetype_enabled(filetype)
  return options.enabled and options.filetypes[filetype] == true
end

return M
