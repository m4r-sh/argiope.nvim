if vim.fn.has("nvim-0.12") ~= 1 then
  error("argiope native package test requires Neovim 0.12 or newer")
end

local source = assert(
  vim.env.ARGIOPE_NATIVE_SOURCE,
  "ARGIOPE_NATIVE_SOURCE is required"
)
local snapshot = assert(
  vim.env.ARGIOPE_NATIVE_SNAPSHOT,
  "ARGIOPE_NATIVE_SNAPSHOT is required"
)
local expected_commit = assert(
  vim.env.ARGIOPE_NATIVE_COMMIT,
  "ARGIOPE_NATIVE_COMMIT is required"
)

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.shadafile = "NONE"
vim.cmd("filetype plugin indent on")

vim.pack.add({
  {
    src = source,
    name = "argiope.nvim",
    version = vim.version.range("0.1"),
  },
}, {
  confirm = false,
  load = true,
})

local setup_options = require("argiope").setup({
  indent = {
    shiftwidth = 3,
  },
})

local function git_output(package_path, ...)
  local command = { "git", "-C", package_path, ... }
  local result = vim.system(command, { text = true }):wait()
  assert(
    result.code == 0,
    ("native package git command failed: %s"):format(result.stderr)
  )
  return vim.trim(result.stdout)
end

function _G.argiope_native_smoke()
  local package_data = vim.pack.get({ "argiope.nvim" }, { info = false })
  assert(#package_data == 1, "vim.pack did not manage exactly one Argiope package")

  local package = package_data[1]
  local expected_path = vim.fs.joinpath(
    vim.fn.stdpath("data"),
    "site",
    "pack",
    "core",
    "opt",
    "argiope.nvim"
  )
  assert(package.active, "vim.pack did not activate Argiope")
  assert(
    vim.fs.normalize(package.path) == vim.fs.normalize(expected_path),
    ("Argiope was installed at an unexpected path: %s"):format(package.path)
  )
  assert(
    package.spec.src == source,
    "vim.pack did not retain the local snapshot source"
  )
  assert(
    package.rev == expected_commit,
    "vim.pack lock data does not match the snapshot commit"
  )

  local package_stat = assert(
    vim.uv.fs_lstat(package.path),
    "vim.pack package directory does not exist"
  )
  assert(
    package_stat.type == "directory",
    "vim.pack package is not a real directory"
  )
  assert(
    vim.uv.fs_realpath(package.path) ~= vim.uv.fs_realpath(snapshot),
    "vim.pack reused the source instead of cloning it"
  )

  local git_stat = assert(
    vim.uv.fs_stat(vim.fs.joinpath(package.path, ".git")),
    "vim.pack package is not a Git clone"
  )
  assert(git_stat.type == "directory", "vim.pack clone has no Git directory")
  assert(
    git_output(package.path, "rev-parse", "HEAD") == expected_commit,
    "vim.pack clone is not checked out at the snapshot commit"
  )
  assert(
    git_output(package.path, "remote", "get-url", "origin") == source,
    "vim.pack clone has an unexpected origin"
  )
  for _, private_path in ipairs({
    ".deps",
    ".nvim-config",
  }) do
    assert(
      vim.uv.fs_stat(vim.fs.joinpath(package.path, private_path)) == nil,
      ("gitignored private path leaked into the package: %s"):format(
        private_path
      )
    )
  end

  vim.cmd("help argiope")
  assert(vim.bo.filetype == "help", ":help argiope did not open a help buffer")
  local help_path = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local expected_help_path =
    vim.fs.normalize(vim.fs.joinpath(package.path, "doc", "argiope.txt"))
  assert(
    vim.uv.fs_realpath(help_path) == vim.uv.fs_realpath(expected_help_path),
    (":help argiope resolved to %s instead of %s"):format(
      help_path,
      expected_help_path
    )
  )
  vim.cmd.close()

  assert(vim.g.loaded_argiope == 1, "Argiope did not auto-load")
  assert(
    vim.fn.exists(":ArgiopeThemeToggle") == 2,
    "Argiope did not register :ArgiopeThemeToggle"
  )
  assert(
    setup_options.indent.shiftwidth == 3,
    "Argiope setup options were not applied"
  )

  vim.cmd.colorscheme("argiope")
  vim.cmd("ArgiopeThemeToggle")
  assert(
    require("argiope").get_theme_mode() == "hybrid",
    ":ArgiopeThemeToggle did not enable hybrid mode"
  )
  vim.cmd("ArgiopeThemeToggle")
  assert(
    require("argiope").get_theme_mode() == "monochrome",
    ":ArgiopeThemeToggle did not restore monochrome mode"
  )

  vim.cmd("enew")
  vim.bo.filetype = "javascript"
  assert(
    vim.b.argiope_attached == true,
    "Argiope did not attach to a JavaScript buffer"
  )
  assert(
    vim.b.argiope_highlight_attached == true,
    "Argiope highlighting did not attach"
  )
  assert(vim.bo.shiftwidth == 3, "Argiope setup did not set shiftwidth=3")
  assert(vim.bo.expandtab, "Argiope did not enable expandtab")
end
