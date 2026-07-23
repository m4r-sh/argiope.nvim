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
end)
