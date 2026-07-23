if vim.fn.has("nvim-0.12") ~= 1 then
  error("argiope development requires Neovim 0.12 or newer")
end

local root = assert(vim.env.ARGIOPE_ROOT, "ARGIOPE_ROOT is not set")
local deps = vim.fs.joinpath(root, ".deps")
local nvim_treesitter = vim.fs.joinpath(deps, "nvim-treesitter")

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.signcolumn = "yes"

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:append(vim.fs.joinpath(deps, "runtime"))
vim.opt.runtimepath:append(nvim_treesitter)
vim.opt.runtimepath:append(vim.fs.joinpath(deps, "nvim-treesitter", "runtime"))
vim.opt.runtimepath:append(vim.fs.joinpath(root, "after"))

vim.cmd("filetype plugin indent on")
vim.cmd("runtime plugin/argiope.lua")
require("argiope").setup()
vim.cmd.colorscheme("argiope")

-- Loading the development colorscheme during startup can make Neovim retain
-- its initial empty buffer instead of entering the first command-line file.
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
  desc = "Open the first argiope development file",
})
