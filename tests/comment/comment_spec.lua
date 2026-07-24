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

local function position(bufnr, line, column)
  return { bufnr, line, column, 0 }
end

local function select_text(bufnr, line, start_column, text)
  return require("argiope.comment").toggle_selection(
    bufnr,
    position(bufnr, line, start_column),
    position(bufnr, line, start_column + #text - 1),
    "v"
  )
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

  it("toggles the exact characterwise selection on one line", function()
    local bufnr = parse({
      "const style = css`",
      "    margin: 0; color: red;",
      "`",
    })
    local text = "margin: 0;"

    assert.is_true(select_text(bufnr, 2, 5, text))
    assert.are.equal(
      "    ${''/* margin: 0; */} color: red;",
      helpers.buffer_lines(bufnr)[2]
    )

    local wrapped = "${''/* margin: 0; */}"
    assert.is_true(select_text(bufnr, 2, 5, wrapped))
    assert.are.equal("    margin: 0; color: red;", helpers.buffer_lines(bufnr)[2])

    assert.is_true(select_text(bufnr, 2, 5, text))
    assert.is_true(select_text(bufnr, 2, 12, text))
    assert.are.equal("    margin: 0; color: red;", helpers.buffer_lines(bufnr)[2])
  end)

  it("reads the active Visual selection through the public API", function()
    local bufnr = parse({
      "const style = css`",
      "    margin: 0; color: red;",
      "`",
    })
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
    vim.cmd("normal! v9l")

    assert.are.equal("v", vim.fn.mode())
    assert.is_true(require("argiope").toggle_interpolation_selection(bufnr))
    assert.are.equal(
      "    ${''/* margin: 0; */} color: red;",
      helpers.buffer_lines(bufnr)[2]
    )
  end)

  it("uses one reversible wrapper for a multiline characterwise selection", function()
    local bufnr = parse({
      "const style = css`",
      "    color: red;",
      "    margin: 0;",
      "`",
    })
    local comment = require("argiope.comment")

    assert.is_true(comment.toggle_selection(
      bufnr,
      position(bufnr, 2, 5),
      position(bufnr, 3, 10),
      "v"
    ))
    assert.are.same({
      "    ${''/* color: red;",
      "    margin */}: 0;",
    }, vim.api.nvim_buf_get_lines(bufnr, 1, 3, false))

    assert.is_true(comment.toggle_selection(
      bufnr,
      position(bufnr, 2, 5),
      position(bufnr, 3, 14),
      "v"
    ))
    assert.are.same({
      "    color: red;",
      "    margin: 0;",
    }, vim.api.nvim_buf_get_lines(bufnr, 1, 3, false))
  end)

  it("turns exact inner or outer interpolation selections into no-ops", function()
    local original = "const view = html`<h1>${title}</h1>`"
    local bufnr = parse({ original })
    local outer = "${title}"
    local outer_start = assert(original:find(outer, 1, true))

    assert.is_true(select_text(bufnr, 1, outer_start, outer))
    assert.are.equal(
      "const view = html`<h1>${''/* title */}</h1>`",
      helpers.buffer_lines(bufnr)[1]
    )

    local wrapped = "${''/* title */}"
    assert.is_true(select_text(bufnr, 1, outer_start, wrapped))
    assert.are.equal(original, helpers.buffer_lines(bufnr)[1])

    local inner_start = assert(original:find("title", 1, true))
    assert.is_true(select_text(bufnr, 1, inner_start, "title"))
    assert.are.equal(
      "const view = html`<h1>${''/* title */}</h1>`",
      helpers.buffer_lines(bufnr)[1]
    )

    assert.is_true(select_text(bufnr, 1, inner_start, "''/* title */"))
    assert.are.equal(original, helpers.buffer_lines(bufnr)[1])
  end)
end)
