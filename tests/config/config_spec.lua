local argiope = require("argiope")
local config = require("argiope.config")

describe("Argiope configuration", function()
  local buffers = {}

  after_each(function()
    argiope.setup()
    for _, bufnr in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
    buffers = {}
  end)

  it("rejects unsupported tag languages without changing active configuration", function()
    argiope.setup({
      tags = {
        prose = "markdown",
      },
    })
    local before = vim.deepcopy(config.get())

    local ok, err = pcall(argiope.setup, {
      tags = {
        icon = "svg",
      },
    })

    assert.is_false(ok)
    assert.matches(
      "must map to css, html, javascript, or markdown",
      tostring(err),
      1,
      true
    )
    assert.are.same(before, config.get())
  end)

  it("rejects unsupported filetypes and invalid theme inheritance", function()
    local filetype_ok, filetype_error = pcall(argiope.setup, {
      filetypes = {
        typescript = true,
      },
    })
    assert.is_false(filetype_ok)
    assert.matches("unsupported filetype", tostring(filetype_error), 1, true)

    local variant_ok, variant_error = pcall(argiope.setup, {
      theme = { variant = "ultraviolet" },
    })
    assert.is_false(variant_ok)
    assert.matches("unknown theme.variant", tostring(variant_error), 1, true)

    local inherited_ok, inherited_error = pcall(argiope.setup, {
      theme = {
        definitions = {
          dusk = { extends = "ultraviolet" },
        },
      },
    })
    assert.is_false(inherited_ok)
    assert.matches("extends unknown theme", tostring(inherited_error), 1, true)
  end)

  it("registers inherited themes and can override generated built-ins", function()
    argiope.setup({
      theme = {
        variant = "dusk",
        definitions = {
          dusk = {
            extends = "aurantia",
            name = "Dusk",
            base = { bg = "#101218" },
          },
          aurantia = {
            base = { selection = "#202438" },
          },
        },
      },
    })

    local themes = require("argiope.palette")
    assert.are.equal("#101218", themes.profile("dusk").base.bg)
    assert.are.equal("#202438", themes.profile("dusk").base.selection)
    assert.are.equal("#202438", themes.profile("aurantia").base.selection)
    assert.are.equal("Dusk", themes.profile("dusk").name)
  end)

  it("restores buffer indentation options when indentation is disabled", function()
    argiope.setup({ enabled = false })
    vim.cmd("enew!")
    local bufnr = vim.api.nvim_get_current_buf()
    table.insert(buffers, bufnr)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "const view = html`<main></main>`",
    })
    vim.bo[bufnr].filetype = "javascript"
    vim.bo[bufnr].autoindent = false
    vim.bo[bufnr].expandtab = false
    vim.bo[bufnr].indentexpr = "42"
    vim.bo[bufnr].indentkeys = "o,O"
    vim.bo[bufnr].shiftwidth = 6
    vim.bo[bufnr].softtabstop = 7

    argiope.setup({
      indent = {
        enabled = true,
        expandtab = true,
        shiftwidth = 3,
      },
    })

    assert.are.equal(require("argiope.indent").expression, vim.bo[bufnr].indentexpr)
    assert.are.equal(3, vim.bo[bufnr].shiftwidth)
    assert.are.equal(3, vim.bo[bufnr].softtabstop)
    assert.is_true(vim.bo[bufnr].expandtab)
    assert.is_true(vim.bo[bufnr].autoindent)

    argiope.setup({
      indent = {
        enabled = false,
      },
    })

    assert.are.equal("42", vim.bo[bufnr].indentexpr)
    assert.are.equal("o,O", vim.bo[bufnr].indentkeys)
    assert.are.equal(6, vim.bo[bufnr].shiftwidth)
    assert.are.equal(7, vim.bo[bufnr].softtabstop)
    assert.is_false(vim.bo[bufnr].expandtab)
    assert.is_false(vim.bo[bufnr].autoindent)
  end)
end)
