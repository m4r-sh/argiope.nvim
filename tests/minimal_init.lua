if vim.fn.has("nvim-0.12") ~= 1 then
  error("argiope tests require Neovim 0.12 or newer")
end

local source = debug.getinfo(1, "S").source:sub(2)
local tests_dir = vim.fs.dirname(vim.fs.normalize(source))
local root = vim.fs.dirname(tests_dir)
local deps = vim.fs.joinpath(root, ".deps")
local nvim_treesitter = vim.fs.joinpath(deps, "nvim-treesitter")

vim.g.argiope_test_root = root

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(vim.fs.joinpath(deps, "runtime"))
vim.opt.runtimepath:append(nvim_treesitter)
vim.opt.runtimepath:append(vim.fs.joinpath(deps, "nvim-treesitter", "runtime"))
vim.opt.runtimepath:append(vim.fs.joinpath(root, "after"))
vim.opt.runtimepath:append(vim.fs.joinpath(deps, "plenary.nvim"))

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.shadafile = "NONE"

vim.cmd("filetype plugin indent on")
vim.cmd("runtime plugin/plenary.vim")
dofile(vim.fs.joinpath(nvim_treesitter, "plugin", "query_predicates.lua"))

require("argiope").setup()
vim.cmd.colorscheme("argiope")
