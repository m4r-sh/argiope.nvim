if vim.g.loaded_argiope == 1 then
  return
end

vim.g.loaded_argiope = 1
require("argiope")._load()
