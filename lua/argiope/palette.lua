local generated = require("argiope.generated.themes")

if generated.schema ~= 1 then
  error(("argiope: unsupported generated theme schema %s"):format(tostring(generated.schema)))
end

local M = {}
local builtins = vim.deepcopy(generated.themes)

local function without_extends(definition)
  local copy = vim.deepcopy(definition)
  copy.extends = nil
  return copy
end

local function validate_theme(name, theme)
  if type(theme.name) ~= "string" or theme.name == "" then
    error(("argiope: theme %q must have a name"):format(name))
  end
  if theme.background ~= "dark" and theme.background ~= "light" then
    error(("argiope: theme %q background must be dark or light"):format(name))
  end
  if type(theme.base) ~= "table" or type(theme.base.bg) ~= "string" or type(theme.base.fg) ~= "string" then
    error(("argiope: theme %q must define base.bg and base.fg"):format(name))
  end
  if type(theme.languages) ~= "table" then
    error(("argiope: theme %q must define languages"):format(name))
  end
  for _, language in ipairs({
    "javascript",
    "javascript_embedded",
    "html",
    "css",
    "markdown",
    "svg",
    "glsl",
    "wgsl",
  }) do
    local definition = theme.languages[language]
    if type(definition) ~= "table" or type(definition.colors) ~= "table" or type(definition.roles) ~= "table" then
      error(("argiope: theme %q must define languages.%s colors and roles"):format(name, language))
    end
  end
end

function M.reset(definitions)
  definitions = definitions or {}
  if type(definitions) ~= "table" then
    error("argiope: theme.definitions must be a table")
  end
  local themes = vim.deepcopy(builtins)
  local resolved = {}
  local resolving = {}

  local function resolve(name)
    if resolved[name] then return resolved[name] end
    if resolving[name] then
      error(("argiope: circular theme inheritance involving %q"):format(name))
    end
    local definition = definitions[name]
    if definition == nil then return themes[name] end
    if type(name) ~= "string" or type(definition) ~= "table" then
      error("argiope: theme.definitions must map names to tables")
    end
    resolving[name] = true
    local parent
    if definition.extends ~= nil then
      if type(definition.extends) ~= "string" then
        error(("argiope: theme %q extends must be a string"):format(name))
      end
      parent = resolve(definition.extends)
      if not parent then
        error(("argiope: theme %q extends unknown theme %q"):format(name, definition.extends))
      end
    elseif themes[name] then
      parent = themes[name]
    end
    local theme = vim.tbl_deep_extend("force", vim.deepcopy(parent or {}), without_extends(definition))
    validate_theme(name, theme)
    themes[name] = theme
    resolved[name] = theme
    resolving[name] = nil
    return theme
  end

  for name in pairs(definitions) do resolve(name) end
  for name, theme in pairs(themes) do validate_theme(name, theme) end
  M.profiles = themes
  if not themes[M.current] then M.current = "aurantia" end
  return themes
end

function M.select(name)
  local profile = M.profiles[name]
  if not profile then
    error(("argiope: unknown theme variant %q"):format(tostring(name)))
  end
  M.current = name
  M.background = profile.background
  M.base = profile.base
  return profile
end

function M.profile(name)
  return M.profiles[name or M.current]
end

function M.variants()
  local variants = vim.tbl_keys(M.profiles)
  table.sort(variants)
  return variants
end

M.reset()
M.select("aurantia")

return M
