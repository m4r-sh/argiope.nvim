local M = {}

local function map(mode, lhs, rhs, description, options)
  vim.keymap.set(
    mode,
    lhs,
    rhs,
    vim.tbl_extend("force", {
      desc = description,
      silent = true,
    }, options or {})
  )
end

function M.setup(options)
  options = options or {}

  map("n", "<leader>w", "<Cmd>write<CR>", "Write buffer")
  map("n", "<leader>q", "<Cmd>confirm quit<CR>", "Quit window")
  map("n", "[b", "<Cmd>bprevious<CR>", "Previous buffer")
  map("n", "]b", "<Cmd>bnext<CR>", "Next buffer")
  map("n", "<leader>bd", "<Cmd>bdelete<CR>", "Delete buffer")
  map("n", "<Esc>", "<Cmd>nohlsearch<CR>", "Clear search highlight")
  map("n", "<leader>hi", "<Cmd>Inspect<CR>", "Inspect highlight captures")
  map("n", "<leader>ht", "<Cmd>InspectTree<CR>", "Inspect Tree-sitter tree")

  if not options.plugins then
    return
  end

  map("n", "-", "<Cmd>Oil<CR>", "Open parent directory")
  map("n", "<leader>e", "<Cmd>Oil<CR>", "Open file explorer")
  map("n", "<leader>ff", function()
    require("fff").find_files()
  end, "Find files")
  map("n", "<leader>fg", function()
    require("fff").live_grep()
  end, "Live grep")
  map({ "n", "x" }, "<leader>fw", function()
    require("fff").live_grep_under_cursor()
  end, "Search word or selection")
  map("n", "<leader>fz", function()
    require("fff").live_grep({
      grep = {
        modes = { "fuzzy", "plain" },
      },
    })
  end, "Fuzzy live grep")

  local function select_template(capture)
    return function()
      require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
    end
  end

  local function map_template_textobjects(bufnr)
    local options = { buffer = bufnr }
    map(
      { "x", "o" },
      "i`",
      select_template("@template.inner"),
      "Inside template literal",
      options
    )
    map(
      { "x", "o" },
      "a`",
      select_template("@template.outer"),
      "Around template literal",
      options
    )
  end

  local group = vim.api.nvim_create_augroup("workbench_template_textobjects", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "javascript",
    callback = function(event)
      map_template_textobjects(event.buf)
    end,
    desc = "Enable multiline JavaScript template text objects",
  })

  if vim.bo.filetype == "javascript" then
    map_template_textobjects(vim.api.nvim_get_current_buf())
  end
end

return M
