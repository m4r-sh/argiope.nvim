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

  it("rejects unsupported filetypes and palette names", function()
    local filetype_ok, filetype_error = pcall(argiope.setup, {
      filetypes = {
        typescript = true,
      },
    })
    assert.is_false(filetype_ok)
    assert.matches("unsupported filetype", tostring(filetype_error), 1, true)

    local palette_ok, palette_error = pcall(argiope.setup, {
      palettes = {
        html = "ultraviolet",
      },
    })
    assert.is_false(palette_ok)
    assert.matches("unknown palette", tostring(palette_error), 1, true)

    local variant_ok, variant_error = pcall(argiope.setup, {
      theme = { variant = "ultraviolet" },
    })
    assert.is_false(variant_ok)
    assert.matches("unknown theme.variant", tostring(variant_error), 1, true)

    local themed_palette_ok, themed_palette_error = pcall(argiope.setup, {
      theme = {
        palettes = {
          dusk = { html = "cyan" },
        },
      },
    })
    assert.is_false(themed_palette_ok)
    assert.matches("unknown variant", tostring(themed_palette_error), 1, true)
  end)

  it("layers global and per-theme palette overrides over profile defaults", function()
    argiope.setup({
      palettes = { html = "pink" },
      theme = {
        palettes = {
          ocyaloides = { html = "blue", css = "slate" },
        },
      },
    })

    assert.are.equal("gold2", config.get_palettes("aurantia").javascript)
    assert.are.equal("gray", config.get_palettes("ocyaloides").javascript)
    assert.are.equal("pink", config.get_palettes("aurantia").html)
    assert.are.equal("blue", config.get_palettes("ocyaloides").html)
    assert.are.equal("slate", config.get_palettes("ocyaloides").css)
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
