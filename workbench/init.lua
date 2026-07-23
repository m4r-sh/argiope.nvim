if vim.fn.has("nvim-0.12") ~= 1 then
  error("argiope workbench requires Neovim 0.12 or newer")
end

local root = assert(vim.env.ARGIOPE_ROOT, "ARGIOPE_ROOT is not set")
local deps = vim.fs.joinpath(root, ".deps")
local nvim_treesitter = vim.fs.joinpath(deps, "nvim-treesitter")

vim.loader.enable()
dofile(vim.fs.joinpath(root, "dev", "settings.lua"))

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(vim.fs.joinpath(deps, "runtime"))
vim.opt.runtimepath:append(nvim_treesitter)
vim.opt.runtimepath:append(vim.fs.joinpath(nvim_treesitter, "runtime"))
vim.opt.runtimepath:append(vim.fs.joinpath(root, "after"))

vim.cmd("filetype plugin indent on")
vim.cmd("runtime plugin/argiope.lua")
require("argiope").setup()
vim.cmd.colorscheme("argiope")

dofile(vim.fs.joinpath(root, "dev", "plugins.lua")).setup()
dofile(vim.fs.joinpath(root, "dev", "palette.lua"))
dofile(vim.fs.joinpath(root, "dev", "keymaps.lua")).setup({
  plugins = true,
})

-- Loading the local colorscheme during startup can leave the initial empty
-- buffer active instead of opening the first command-line path.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local first_argument = vim.fn.argv(0)
    if
      first_argument ~= ""
      and vim.api.nvim_buf_get_name(0) == ""
      and vim.api.nvim_buf_line_count(0) == 1
      and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
    then
      vim.cmd.edit(vim.fn.fnameescape(first_argument))
      vim.cmd("filetype detect")
    end
  end,
  desc = "Open the first Argiope workbench path",
})
