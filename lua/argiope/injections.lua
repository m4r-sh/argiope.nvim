local registry = require("argiope.registry")
local config = require("argiope.config")

local M = {}
local managed_languages = {
  css = true,
  html = true,
  markdown = true,
}

local function captured_nodes(match, capture)
  local nodes = match[capture]
  if not nodes then
    return {}
  end
  if type(nodes) == "table" then
    return nodes
  end
  return { nodes }
end

local function resolved_languages(match, source, predicate)
  local languages = {}
  for _, node in ipairs(captured_nodes(match, predicate[2])) do
    local tag = vim.treesitter.get_node_text(node, source)
    -- Keep unknown entries countable: inserting nil would make the table look
    -- empty and prevent the unknown-tag predicate from matching.
    table.insert(languages, registry.resolve(tag) or false)
  end
  return languages
end

local function install_predicates()
  vim.treesitter.query.add_predicate("argiope-language?", function(match, _, source, predicate)
    if not config.get().enabled then
      return false
    end

    local expected = predicate[3]
    local languages = resolved_languages(match, source, predicate)
    if #languages == 0 then
      return false
    end

    for _, language in ipairs(languages) do
      if language ~= expected then
        return false
      end
    end
    return true
  end, { force = true })

  vim.treesitter.query.add_predicate("argiope-unknown?", function(match, _, source, predicate)
    local options = config.get()
    if not options.enabled or not options.highlight.enabled then
      return false
    end

    local languages = resolved_languages(match, source, predicate)
    if #languages == 0 then
      return false
    end

    for _, language in ipairs(languages) do
      if language ~= false then
        return false
      end
    end
    return true
  end, { force = true })

  vim.treesitter.query.add_predicate("argiope-unmanaged?", function(match, _, source, predicate)
    if not config.get().enabled then
      return true
    end

    local languages = resolved_languages(match, source, predicate)
    if #languages == 0 then
      return false
    end

    for _, language in ipairs(languages) do
      if managed_languages[language] then
        return false
      end
    end
    return true
  end, { force = true })

  vim.treesitter.query.add_predicate("argiope-highlight?", function()
    local options = config.get()
    return options.enabled and options.highlight.enabled
  end, { force = true })
end

local function has_predicate(query, pattern, name, capture, ...)
  local expected = { ... }
  for _, predicate in ipairs(pattern) do
    if
      predicate[1] == name
      and query.captures[predicate[2]] == capture
      and #predicate == #expected + 2
    then
      local matches = true
      for index, value in ipairs(expected) do
        if predicate[index + 2] ~= value then
          matches = false
          break
        end
      end
      if matches then
        return true
      end
    end
  end
  return false
end

local function has_directive(pattern, name, ...)
  local expected = { ... }
  for _, directive in ipairs(pattern) do
    if directive[1] == name and #directive == #expected + 1 then
      local matches = true
      for index, value in ipairs(expected) do
        if directive[index + 1] ~= value then
          matches = false
          break
        end
      end
      if matches then
        return true
      end
    end
  end
  return false
end

local function is_upstream_generic_tag_pattern(query, pattern)
  return not has_predicate(query, pattern, "argiope-unmanaged?", "injection.language")
    and has_predicate(
      query,
      pattern,
      "lua-match?",
      "injection.language",
      "^[a-zA-Z][a-zA-Z0-9]*$"
    )
    and has_predicate(query, pattern, "not-any-of?", "injection.language", "svg", "css")
end

local function is_upstream_css_tag_pattern(query, pattern)
  return not has_predicate(query, pattern, "argiope-unmanaged?", "_argiope_upstream_name")
    and has_predicate(query, pattern, "any-of?", "_name", "css", "keyframes")
    and has_directive(pattern, "set!", "injection.language", "styled")
end

local function disable_conflicting_upstream_patterns()
  local ok, query = pcall(vim.treesitter.query.get, "javascript", "injections")
  if not ok or not query then
    return
  end

  for index, pattern in ipairs(query.info.patterns) do
    if
      is_upstream_generic_tag_pattern(query, pattern)
      or is_upstream_css_tag_pattern(query, pattern)
    then
      query.query:disable_pattern(index)
    end
  end
end

function M.install()
  install_predicates()
  disable_conflicting_upstream_patterns()
end

return M
