local M = require("argiope.generated.palette")

M.monochrome.beige = M.monochrome.gold

function M.get(name)
  return M.monochrome[name]
end

return M
