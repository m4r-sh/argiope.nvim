vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.signcolumn = "yes"
vim.opt.undofile = true
vim.opt.confirm = true
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 4
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↳ "

if vim.uv.os_uname().sysname == "Darwin" then
  vim.opt.clipboard:append("unnamedplus")
end
