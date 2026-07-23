local helpers = require("tests.helpers")

local function captures_at(bufnr, lines, row, needle, offset)
  local column = assert(lines[row + 1]:find(needle, 1, true), "missing " .. needle) - 1
  return vim.treesitter.get_captures_at_pos(bufnr, row, column + (offset or 0))
end

local function has_capture(captures, language, capture)
  for _, item in ipairs(captures) do
    if item.lang == language and item.capture == capture then
      return true
    end
  end
  return false
end

local function highlight_color(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
end

local function color(hex)
  return tonumber(hex:sub(2), 16)
end

describe("zilk-ui integration", function()
  local lines
  local bufnr

  before_each(function()
    require("argiope").setup()
    vim.cmd.colorscheme("argiope")
    lines = helpers.read_lines(helpers.integration_fixture_path("zilk-ui.js"))
    bufnr = helpers.new_javascript_buffer(lines)
    assert(vim.treesitter.get_parser(bufnr, "javascript"):parse(true))
  end)

  it("keeps unquoted HTML attribute interpolations and body interpolations in JavaScript", function()
    assert.is_true(has_capture(captures_at(bufnr, lines, 5, "${WRAP}", 2), "javascript", "variable"))
    assert.is_true(has_capture(captures_at(bufnr, lines, 6, "${BTN}", 2), "javascript", "variable"))
    assert.is_true(has_capture(captures_at(bufnr, lines, 7, "${LABEL}", 2), "javascript", "variable"))
    assert.is_true(has_capture(captures_at(bufnr, lines, 8, "${title}", 2), "javascript", "variable"))
    assert.is_true(has_capture(captures_at(bufnr, lines, 9, "span"), "html", "tag"))
  end)

  it("uses the surrounding HTML structure to indent a standalone interpolation", function()
    vim.cmd("normal! gg=G")

    assert.are.equal("        ${title}", helpers.buffer_lines(bufnr)[9])
    assert.are.equal("    background: #fff;", helpers.buffer_lines(bufnr)[17])
  end)

  it("styles plain CSS values as CSS and dims declaration delimiters", function()
    assert.is_true(has_capture(captures_at(bufnr, lines, 17, "solid"), "css", "value"))
    assert.is_true(has_capture(captures_at(bufnr, lines, 17, "red"), "css", "value"))
    assert.is_true(
      has_capture(captures_at(bufnr, lines, 17, ":"), "css", "punctuation.delimiter")
    )
    assert.is_true(
      has_capture(captures_at(bufnr, lines, 17, ";"), "css", "punctuation.delimiter")
    )

    assert.are.equal(color("#57A880"), highlight_color("@value.css"))
    assert.are.equal(color("#61756E"), highlight_color("@punctuation.delimiter.css"))
  end)

  it("keeps Markdown prose neutral while styling list syntax and text with its palette", function()
    assert.is_true(has_capture(captures_at(bufnr, lines, 25, "This"), "markdown", "spell"))
    assert.is_true(has_capture(captures_at(bufnr, lines, 27, "-"), "markdown", "markup.list"))
    assert.is_true(
      has_capture(captures_at(bufnr, lines, 27, "Feature"), "markdown", "markup.list.text")
    )

    local palette = assert(
      require("argiope.palette").get(require("argiope.config").defaults.palettes.markdown)
    )
    assert.are.equal(color(palette.gray), highlight_color("@spell.markdown"))
    assert.are.equal(color(palette.main), highlight_color("@markup.list.markdown"))
    assert.are.equal(color(palette.soft), highlight_color("@markup.list.text.markdown"))
  end)
end)
