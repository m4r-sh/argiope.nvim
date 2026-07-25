local helpers = require("tests.helpers")

describe("tagged-template joins", function()
  before_each(function()
    require("argiope").setup()
  end)

  it("joins an HTML element without spaces at its tag boundaries", function()
    local bufnr = helpers.new_javascript_buffer({
      "const view = html`",
      "  <div class=${BTN.LABEL}>",
      "    ${label}",
      "  </div>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    helpers.feed("J")
    helpers.feed("J")

    assert.are.same({
      "const view = html`",
      "  <div class=${BTN.LABEL}>${label}</div>",
      "`",
    }, helpers.buffer_lines(bufnr))
  end)

  it("supports a count when compacting a complete HTML element", function()
    local bufnr = helpers.new_javascript_buffer({
      "const view = html`",
      "  <div class=${BTN.LABEL}>",
      "    ${label}",
      "  </div>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    helpers.feed("3J")

    assert.are.equal(
      "  <div class=${BTN.LABEL}>${label}</div>",
      helpers.buffer_lines(bufnr)[2]
    )
  end)

  it("compacts a complete linewise visual selection", function()
    local original = {
      "const view = html`",
      "  <div class=${BTN.LABEL}>",
      "    ${label}",
      "  </div>",
      "`",
    }
    local bufnr = helpers.new_javascript_buffer(original)
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    helpers.feed("V2jJ")

    assert.are.equal(
      "  <div class=${BTN.LABEL}>${label}</div>",
      helpers.buffer_lines(bufnr)[2]
    )

    helpers.feed("u")
    assert.are.same(original, helpers.buffer_lines(bufnr))
  end)

  it("keeps a space when joining ordinary HTML prose", function()
    local bufnr = helpers.new_javascript_buffer({
      "const view = html`",
      "  hello",
      "  world",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    helpers.feed("J")

    assert.are.equal("  hello world", helpers.buffer_lines(bufnr)[2])
  end)

  it("preserves meaningful whitespace between complete sibling elements", function()
    local bufnr = helpers.new_javascript_buffer({
      "const view = html`",
      "  <span>first</span>",
      "  <span>second</span>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    helpers.feed("J")

    assert.are.equal(
      "  <span>first</span> <span>second</span>",
      helpers.buffer_lines(bufnr)[2]
    )
  end)

  it("keeps native joining outside a tagged HTML template", function()
    local bufnr = helpers.new_javascript_buffer({
      "const first = 1;",
      "const second = 2;",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    helpers.feed("J")

    assert.are.equal(
      "const first = 1; const second = 2;",
      helpers.buffer_lines(bufnr)[1]
    )
  end)

  it("does not replace an existing J mapping", function()
    vim.cmd("enew!")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.keymap.set("n", "J", "<Cmd>let g:argiope_custom_join = 1<CR>", {
      buffer = bufnr,
      desc = "Custom join",
    })
    vim.bo[bufnr].filetype = "javascript"

    local mapping = vim.fn.maparg("J", "n", false, true)
    assert.are.equal("Custom join", mapping.desc)
  end)

  it("can disable the HTML-aware J mapping", function()
    require("argiope").setup({
      join = {
        enabled = false,
      },
    })
    vim.cmd("enew!")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.bo[bufnr].filetype = "javascript"

    assert.are.same({}, vim.fn.maparg("J", "n", false, true))
    assert.are.same({}, vim.fn.maparg("J", "x", false, true))
  end)
end)
