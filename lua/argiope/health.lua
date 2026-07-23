local M = {}

function M.check()
  vim.health.start("argiope.nvim")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim 0.12+ is available")
  else
    vim.health.error("Neovim 0.12+ is required")
  end

  for _, language in ipairs({ "javascript", "html", "css", "markdown", "markdown_inline" }) do
    local ok, loaded_or_error = pcall(vim.treesitter.language.add, language)
    if ok and loaded_or_error then
      vim.health.ok(("%s Tree-sitter parser is available"):format(language))
    else
      local detail = ok and "parser could not be loaded" or tostring(loaded_or_error)
      vim.health.error(("%s Tree-sitter parser is unavailable"):format(language), {
        detail,
        (
          "Install it with :lua require('nvim-treesitter').install(%q):wait(300000)"
        ):format(language),
      })
    end
  end

  local query_checks = {
    { "javascript", "injections" },
    { "javascript", "highlights" },
    { "html", "highlights" },
    { "html", "indents" },
    { "css", "highlights" },
    { "css", "indents" },
    { "markdown", "highlights" },
    { "markdown_inline", "highlights" },
  }
  for _, check in ipairs(query_checks) do
    local language, query_type = check[1], check[2]
    local ok, query = pcall(vim.treesitter.query.get, language, query_type)
    if ok and query then
      vim.health.ok(("%s %s query is available"):format(language, query_type))
    else
      vim.health.error(("%s %s query is unavailable"):format(language, query_type), {
        ("Update %s through nvim-treesitter with :TSUpdate %s"):format(language, language),
      })
    end
  end

  local inherited_query_files = {
    "queries/ecma/highlights.scm",
    "queries/ecma/injections.scm",
    "queries/jsx/highlights.scm",
    "queries/html_tags/highlights.scm",
    "queries/html_tags/indents.scm",
  }
  for _, path in ipairs(inherited_query_files) do
    local files = vim.api.nvim_get_runtime_file(path, false)
    if #files > 0 then
      vim.health.ok(("%s is available"):format(path))
    else
      local package_name = path:match("^queries/([^/]+)")
      vim.health.error(("%s is unavailable"):format(path), {
        (
          "Install inherited queries with :lua require('nvim-treesitter').install(%q):wait(300000)"
        ):format(package_name),
      })
    end
  end

  local indent_ok, indent_error = pcall(require, "nvim-treesitter.indent")
  if indent_ok then
    vim.health.ok("nvim-treesitter language-aware indent engine is available")
  else
    vim.health.error("nvim-treesitter language-aware indent engine is unavailable", {
      tostring(indent_error),
      "Embedded templates will use flat fallback indentation.",
    })
  end
end

return M
