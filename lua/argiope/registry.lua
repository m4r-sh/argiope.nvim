local M = {}

local entries = {}

local function normalize(tag)
  return type(tag) == "string" and tag:gsub("%s+", "") or tag
end

function M.reset(tags)
  entries = {}
  for tag, language in pairs(tags or {}) do
    entries[normalize(tag)] = language
  end
end

function M.resolve(tag)
  tag = normalize(tag)

  local direct = entries[tag]
  if direct then
    return direct
  end

  -- Treat the final property of a member expression as a tag alias. This
  -- makes namespace-like spellings such as `ui.md` resolve through the same
  -- registry entry as a bare `md` tag.
  local property = tag and tag:match("%.([%a_$][%w_$]*)$")
  return property and entries[property] or nil
end

function M.entries()
  return vim.deepcopy(entries)
end

return M
