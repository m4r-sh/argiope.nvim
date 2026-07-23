local registry = require("argiope.registry")

local M = {}

local function query_path()
  local source = debug.getinfo(1, "S").source:sub(2)
  local module_dir = vim.fs.dirname(vim.fs.normalize(source))
  local root = vim.fs.dirname(vim.fs.dirname(module_dir))
  return vim.fs.joinpath(root, "queries", "javascript", "injections.scm")
end

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
end

function M.install()
  install_predicates()
  local path = query_path()
  local lines = vim.fn.readfile(path)
  vim.treesitter.query.set("javascript", "injections", table.concat(lines, "\n"))
end

return M
