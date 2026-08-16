local generated = require("argiope.generated.palette")

local M = {
  profiles = generated.profiles,
}

function M.select(profile_name)
  local profile = M.profiles[profile_name]
  if not profile then
    error(("argiope: unknown theme variant %q"):format(tostring(profile_name)))
  end

  M.current = profile_name
  M.background = profile.background
  M.base = profile.base
  M.monochrome = profile.monochrome
  M.monochrome.beige = M.monochrome.gold
  M.hsl = { monochrome = profile.hsl }
  M.hsl.monochrome.beige = M.hsl.monochrome.gold
  return profile
end

function M.get(name, profile_name)
  if profile_name then
    local profile = M.profiles[profile_name]
    return profile and (name == "beige" and profile.monochrome.gold or profile.monochrome[name])
  end
  return M.monochrome[name]
end

function M.profile(name)
  return M.profiles[name or M.current]
end

function M.variants()
  local variants = vim.tbl_keys(M.profiles)
  table.sort(variants)
  return variants
end

M.select("aurantia")

return M
