local M = {}

function M.check()
  vim.health.start("argiope.nvim")

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim 0.12+ is available")
  else
    vim.health.error("Neovim 0.12+ is required")
  end

  for _, language in ipairs({ "javascript", "html", "css", "markdown", "markdown_inline" }) do
    local ok, err = pcall(vim.treesitter.language.add, language)
    if ok then
      vim.health.ok(("%s Tree-sitter parser is available"):format(language))
    else
      vim.health.error(("%s Tree-sitter parser is unavailable"):format(language), { tostring(err) })
    end
  end

  local query_checks = {
    { "javascript", "injections" },
    { "javascript", "highlights" },
    { "html", "highlights" },
    { "css", "highlights" },
    { "markdown", "highlights" },
    { "markdown_inline", "highlights" },
  }
  for _, check in ipairs(query_checks) do
    local language, query_type = check[1], check[2]
    local ok, query = pcall(vim.treesitter.query.get, language, query_type)
    if ok and query then
      vim.health.ok(("%s %s query is available"):format(language, query_type))
    else
      vim.health.error(("%s %s query is unavailable"):format(language, query_type))
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
