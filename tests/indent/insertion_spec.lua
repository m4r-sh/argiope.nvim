local helpers = require("tests.helpers")

describe("insertion indentation", function()
  it("indents Enter inside an empty tagged template", function()
    local line = "const view = html``"
    helpers.new_javascript_buffer({ line })
    local opening = assert(line:find("``", 1, true))
    vim.api.nvim_win_set_cursor(0, { 1, opening - 1 })

    helpers.feed("a<CR>body<CR><Esc>")

    assert.are.same({
      "const view = html`",
      "  body",
      "`",
    }, helpers.buffer_lines())
  end)

  it("indents Enter inside an unregistered text template", function()
    local line = "const copy = txt``"
    helpers.new_javascript_buffer({ line })
    local opening = assert(line:find("``", 1, true))
    vim.api.nvim_win_set_cursor(0, { 1, opening - 1 })

    helpers.feed("a<CR>content<CR><Esc>")

    assert.are.same({
      "const copy = txt`",
      "  content",
      "`",
    }, helpers.buffer_lines())
  end)

  it("indents a line opened with o inside template content", function()
    helpers.new_javascript_buffer({
      "const view = html`",
      "  <main>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 2 })

    helpers.feed("o<section><Esc>")

    assert.are.same({
      "const view = html`",
      "  <main>",
      "  <section>",
      "`",
    }, helpers.buffer_lines())
  end)

  it("indents a line opened with O before the closing delimiter", function()
    helpers.new_javascript_buffer({
      "const view = html`",
      "  <main>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 3, 0 })

    helpers.feed("O<footer><Esc>")

    assert.are.same({
      "const view = html`",
      "  <main>",
      "  <footer>",
      "`",
    }, helpers.buffer_lines())
  end)

  it("reparses a closing tag completed after an earlier indent calculation", function()
    local bufnr = helpers.new_javascript_buffer({
      "const view = html`",
      "  <a>",
      "    <span>",
      "      ${name}",
      "      </span",
      "    </a>",
      "`",
    })

    -- Simulate Insert mode asking for indentation while the end tag is still
    -- incomplete, then asking again as soon as the user finishes it.
    require("argiope.indent").get(bufnr, 5)
    vim.api.nvim_buf_set_lines(bufnr, 4, 5, false, { "      </span>" })

    assert.are.equal(4, require("argiope.indent").get(bufnr, 5))
  end)

  it("closes a parsed opening tag and places the cursor in its body", function()
    helpers.new_javascript_buffer({
      "const view = html`",
      "  <section class=${WRAP}>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, #"  <section class=${WRAP}>" - 1 })

    helpers.feed("a<CR>")
    assert.are.same({ 3, 3 }, vim.api.nvim_win_get_cursor(0))
    assert.are.equal("    ", helpers.buffer_lines()[3])
    helpers.feed("<Esc>")

    assert.are.same({
      "const view = html`",
      "  <section class=${WRAP}>",
      "    ",
      "  </section>",
      "`",
    }, helpers.buffer_lines())
  end)

  it("does not close void elements", function()
    helpers.new_javascript_buffer({
      "const view = html`",
      "  <img src=${url}>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, #"  <img src=${url}>" - 1 })

    helpers.feed("a<CR><Esc>")

    assert.are.same({
      "const view = html`",
      "  <img src=${url}>",
      "",
      "`",
    }, helpers.buffer_lines())
  end)

  it("closes SVG elements with the same structural behavior", function()
    helpers.new_javascript_buffer({
      "const icon = svg`",
      "  <g transform=${transform}>",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, #"  <g transform=${transform}>" - 1 })

    helpers.feed("a<CR><Esc>")

    assert.are.same({
      "const icon = svg`",
      "  <g transform=${transform}>",
      "    ",
      "  </g>",
      "`",
    }, helpers.buffer_lines())
  end)

  it("preserves a user-defined insert Enter mapping", function()
    local bufnr = helpers.new_javascript_buffer({ "const view = html``" })
    require("argiope").detach(bufnr)
    vim.keymap.set("i", "<CR>", "custom", { buffer = bufnr })

    require("argiope").attach(bufnr)

    assert.are.equal("custom", vim.fn.maparg("<CR>", "i"))
  end)
end)
