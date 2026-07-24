local helpers = require("tests.helpers")

local function parse(lines)
  local bufnr = helpers.new_javascript_buffer(lines)
  vim.api.nvim_set_current_buf(bufnr)
  assert(vim.treesitter.get_parser(bufnr, "javascript"):parse(true))
  return bufnr
end

local function toggle_native(line)
  require("vim._comment").toggle_lines(line, line, { line, 2 })
end

describe("tagged-template comments", function()
  before_each(function()
    require("argiope").setup()
  end)

  it("uses HTML comments for HTML template content", function()
    local bufnr = parse({
      "const view = html`",
      "  <main>content</main>",
      "`",
    })

    toggle_native(2)
    assert.are.equal("  <!-- <main>content</main> -->", helpers.buffer_lines(bufnr)[2])

    assert(vim.treesitter.get_parser(bufnr, "javascript"):parse(true))
    toggle_native(2)
    assert.are.equal("  <main>content</main>", helpers.buffer_lines(bufnr)[2])
  end)

  it("keeps CSS, Markdown, and raw JavaScript comment strings explicit", function()
    local cases = {
      {
        lines = { "const style = css`", "  color: red;", "`" },
        commented = "  /* color: red; */",
      },
      {
        lines = { "const notes = md`", "  prose", "`" },
        commented = "  <!-- prose -->",
      },
      {
        lines = { "const source = raw.js`", "  const answer = 42", "`" },
        commented = "  // const answer = 42",
      },
    }

    for _, case in ipairs(cases) do
      local bufnr = parse(case.lines)
      toggle_native(2)
      assert.are.equal(case.commented, helpers.buffer_lines(bufnr)[2])
    end
  end)

  it("toggles selected lines with reversible empty-interpolation comments", function()
    local lines = {
      "const style = css`",
      "    width: 1.2rem;",
      "    margin: 0;",
      "    padding: 0;",
      "`",
    }
    local bufnr = parse(lines)
    local argiope = require("argiope")

    assert.is_true(argiope.toggle_interpolation_comment(0, 3, 3))
    assert.are.equal(
      "    ${''/* margin: 0; */}",
      helpers.buffer_lines(bufnr)[3]
    )

    assert.is_true(argiope.toggle_interpolation_comment(bufnr, 3, 3))
    assert.are.equal("    margin: 0;", helpers.buffer_lines(bufnr)[3])

    assert.is_true(argiope.toggle_interpolation_comment(bufnr, 2, 4))
    assert.are.same({
      "    ${''/* width: 1.2rem; */}",
      "    ${''/* margin: 0; */}",
      "    ${''/* padding: 0; */}",
    }, vim.api.nvim_buf_get_lines(bufnr, 1, 4, false))

    assert.is_true(argiope.toggle_interpolation_comment(bufnr, 2, 4))
    assert.are.same({
      "    width: 1.2rem;",
      "    margin: 0;",
      "    padding: 0;",
    }, vim.api.nvim_buf_get_lines(bufnr, 1, 4, false))
  end)
end)
