if vim.fn.has("nvim-0.12") ~= 1 then
  error("argiope native package test requires Neovim 0.12 or newer")
end

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.shadafile = "NONE"
vim.cmd("filetype plugin indent on")
