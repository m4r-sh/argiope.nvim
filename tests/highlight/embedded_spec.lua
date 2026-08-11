local helpers = require("tests.helpers")

local function find_position(lines, needle)
  for row, line in ipairs(lines) do
    local column = line:find(needle, 1, true)
    if column then
      return row - 1, column - 1
    end
  end
  error(("could not find %q in fixture"):format(needle))
end

local function captures_at(bufnr, lines, needle, offset)
  local row, column = find_position(lines, needle)
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

local function has_normalized_capture(bufnr, lines, needle, group, offset)
  local row, column = find_position(lines, needle)
  for _, capture in ipairs(
    require("argiope.markdown")._captures_at(bufnr, row, column + (offset or 0))
  ) do
    if capture.group == group then
      return true
    end
  end
  return false
end

local function has_normalized_template_capture(bufnr, lines, needle, group, offset)
  local row, column = find_position(lines, needle)
  for _, capture in ipairs(
    require("argiope.html")._captures_at(bufnr, row, column + (offset or 0))
  ) do
    if capture.group == group then
      return true
    end
  end
  return false
end

local function color(hex)
  return tonumber(hex:sub(2), 16)
end

describe("embedded language highlighting", function()
  local lines
  local bufnr

  before_each(function()
    require("argiope").setup()
    require("argiope.theme").set_mode("monochrome")
    vim.cmd.colorscheme("argiope")
    lines = helpers.read_lines(vim.fs.joinpath(helpers.root, "tests", "fixtures", "highlight", "embedded.js"))
    bufnr = helpers.new_javascript_buffer(lines)
    assert(vim.treesitter.get_parser(bufnr, "javascript"):parse(true))
  end)

  it("creates isolated HTML, CSS, and Markdown language trees", function()
    local languages = {}
    vim.treesitter.get_parser(bufnr, "javascript"):for_each_tree(function(_, language_tree)
      local language = language_tree:lang()
      languages[language] = (languages[language] or 0) + 1
    end)

    assert.are.equal(1, languages.javascript)
    assert.are.equal(1, languages.argiope_html)
    assert.are.equal(1, languages.css)
    assert.are.equal(1, languages.markdown)
    assert.is_true(languages.markdown_inline >= 1)
  end)

  it("uses each injected language's semantic highlight query", function()
    assert.is_true(has_normalized_template_capture(bufnr, lines, "main", "@tag.html"))
    assert.is_true(has_capture(captures_at(bufnr, lines, "background"), "css", "property"))
    assert.is_true(
      has_capture(captures_at(bufnr, lines, "# Embedded Markdown"), "markdown", "markup.heading.1")
    )
  end)

  it("preserves CSS highlighting after an interpolated class selector", function()
    local selector_lines = {
      "const styles = css`",
      "  .${BTN}:hover{",
      "    background: var(--valley);",
      "  }",
      "`",
    }
    local selector_bufnr = helpers.new_javascript_buffer(selector_lines)
    assert(vim.treesitter.get_parser(selector_bufnr, "javascript"):parse(true))

    assert.is_true(
      has_normalized_template_capture(
        selector_bufnr,
        selector_lines,
        "hover",
        "@attribute.css"
      )
    )
    assert.is_true(
      has_normalized_template_capture(
        selector_bufnr,
        selector_lines,
        "background",
        "@property.css"
      )
    )
    assert.is_true(
      has_capture(
        captures_at(selector_bufnr, selector_lines, "${BTN}", 2),
        "javascript",
        "variable"
      )
    )
  end)

  it("isolates script and style child languages while highlighting raw.js separately", function()
    local fixture = helpers.read_lines(
      vim.fs.joinpath(
        helpers.root,
        "tests",
        "fixtures",
        "highlight",
        "script-style.js"
      )
    )
    local nested_bufnr = helpers.new_javascript_buffer(fixture)
    local parser = vim.treesitter.get_parser(nested_bufnr, "javascript")
    assert(parser:parse(true))

    local languages = {}
    parser:for_each_tree(function(_, language_tree)
      local language = language_tree:lang()
      languages[language] = (languages[language] or 0) + 1
    end)

    assert.are.equal(1, languages.javascript)
    assert.are.equal(1, languages.argiope_html)
    assert.are.equal(1, languages.argiope_javascript)
    assert.is_nil(languages.html)
    assert.is_nil(languages.css)

    for _, language in ipairs({ "argiope_html", "argiope_javascript" }) do
      local query = vim.treesitter.query.get(language, "injections")
      if query then
        assert.are.same({}, query.captures)
        assert.are.same({}, query.info.patterns)
      end
    end

    assert.is_true(
      has_capture(
        captures_at(nested_bufnr, fixture, "const LS"),
        "argiope_javascript",
        "keyword"
      )
    )
    assert.is_false(
      has_capture(
        captures_at(nested_bufnr, fixture, "raw.js"),
        "javascript",
        "argiope.unknown.tag"
      )
    )
    assert.is_true(
      has_normalized_template_capture(
        nested_bufnr,
        fixture,
        "<script>",
        "@tag.html",
        1
      )
    )
    assert.is_true(
      has_normalized_template_capture(
        nested_bufnr,
        fixture,
        "--navh",
        "@property.css"
      )
    )

    local palettes = require("argiope.palette")
    local embedded = assert(
      palettes.get(
        require("argiope.config").get_palettes("classic").javascript_embedded
      )
    )
    assert.are.equal(
      color(embedded.main),
      highlight_color("@variable.argiope_javascript")
    )

    require("argiope").toggle_theme()
    assert.are.equal(
      color(palettes.base.beige),
      highlight_color("@variable.javascript")
    )
    assert.are.equal(
      color(embedded.main),
      highlight_color("@variable.argiope_javascript")
    )
    require("argiope").toggle_theme()
  end)

  it("preserves HTML attribute highlighting across unquoted substitutions", function()
    local attribute_lines = {
      "const field = html`",
      "  <textarea",
      "    id=${id}",
      "    name=${name}",
      "    placeholder=${view.placeholder || ''}",
      "    data-type=${view.inputType === 'json' ? 'json' : null}",
      "    ?required=${Boolean(view.required)}",
      "  >",
      "    ${value ?? ''}",
      "  </textarea>",
      "`",
    }
    local attribute_bufnr = helpers.new_javascript_buffer(attribute_lines)
    assert(vim.treesitter.get_parser(attribute_bufnr, "javascript"):parse(true))

    for _, attribute in ipairs({ "id", "name", "placeholder", "data-type", "?required" }) do
      assert.is_true(
        has_normalized_template_capture(
          attribute_bufnr,
          attribute_lines,
          attribute .. "=",
          "@tag.attribute.html"
        ),
        "missing normalized HTML capture for " .. attribute
      )
    end

    assert.is_true(
      has_capture(
        captures_at(attribute_bufnr, attribute_lines, "${view.inputType", 2),
        "javascript",
        "variable"
      )
    )
    assert.is_false(
      has_normalized_template_capture(
        attribute_bufnr,
        attribute_lines,
        "${view.inputType",
        "@nospell.html",
        2
      )
    )
  end)

  it("injects registered member-expression tags by their final property", function()
    local member_lines = {
      "const document = ui.md`",
      "# Member syntax",
      "`",
    }
    local member_bufnr = helpers.new_javascript_buffer(member_lines)
    assert(vim.treesitter.get_parser(member_bufnr, "javascript"):parse(true))

    assert.is_true(
      has_capture(
        captures_at(member_bufnr, member_lines, "# Member syntax"),
        "markdown",
        "markup.heading.1"
      )
    )

    require("argiope").setup({
      tags = {
        prose = "markdown",
      },
    })
    local custom_lines = {
      "const document = ui.prose`",
      "# Custom member alias",
      "`",
    }
    local custom_bufnr = helpers.new_javascript_buffer(custom_lines)
    assert(vim.treesitter.get_parser(custom_bufnr, "javascript"):parse(true))

    assert.is_true(
      has_capture(
        captures_at(custom_bufnr, custom_lines, "# Custom member alias"),
        "markdown",
        "markup.heading.1"
      )
    )
  end)

  it("normalizes host indentation before applying Markdown semantics", function()
    local nested_lines = {
      "function docs(title) {",
      "  return md`",
      "    # ${title}",
      "",
      "    Plain paragraph with **bold** and [link](url).",
      "",
      "    - Feature one",
      "    - Feature two",
      "  `",
      "}",
    }
    local nested_bufnr = helpers.new_javascript_buffer(nested_lines)
    assert(vim.treesitter.get_parser(nested_bufnr, "javascript"):parse(true))

    -- The normal injected parser sees the host's four spaces as a code block.
    assert.is_true(
      has_capture(
        captures_at(nested_bufnr, nested_lines, "# ${title}"),
        "markdown",
        "markup.raw.block"
      )
    )

    assert.is_true(
      has_normalized_capture(
        nested_bufnr,
        nested_lines,
        "# ${title}",
        "@markup.heading.1.markdown"
      )
    )
    assert.is_true(
      has_normalized_capture(
        nested_bufnr,
        nested_lines,
        "Plain paragraph",
        "@spell.markdown"
      )
    )
    assert.is_true(
      has_normalized_capture(
        nested_bufnr,
        nested_lines,
        "**bold**",
        "@markup.strong.markdown_inline",
        2
      )
    )
    assert.is_true(
      has_normalized_capture(
        nested_bufnr,
        nested_lines,
        "- Feature one",
        "@markup.list.markdown"
      )
    )
    assert.is_true(
      has_normalized_capture(
        nested_bufnr,
        nested_lines,
        "Feature one",
        "@markup.list.text.markdown"
      )
    )
    assert.is_false(
      has_normalized_capture(
        nested_bufnr,
        nested_lines,
        "${title}",
        "@markup.heading.1.markdown",
        2
      )
    )
  end)

  it("styles unknown tagged templates gray without changing ordinary templates", function()
    local template_lines = {
      "const unknown = txt`gray ${value}`",
      "const member = ui.txt`also gray`",
      "const ordinary = `gold ${value}`",
    }
    local template_bufnr = helpers.new_javascript_buffer(template_lines)
    assert(vim.treesitter.get_parser(template_bufnr, "javascript"):parse(true))

    assert.is_true(
      has_capture(
        captures_at(template_bufnr, template_lines, "txt"),
        "javascript",
        "argiope.unknown.tag"
      )
    )
    assert.is_true(
      has_capture(
        captures_at(template_bufnr, template_lines, "gray"),
        "javascript",
        "argiope.unknown.template"
      )
    )
    assert.is_true(
      has_capture(
        captures_at(template_bufnr, template_lines, "txt", 3),
        "javascript",
        "argiope.unknown.delimiter"
      )
    )
    assert.is_true(
      has_capture(
        captures_at(template_bufnr, template_lines, "ui.txt"),
        "javascript",
        "argiope.unknown.tag"
      )
    )
    assert.is_false(
      has_capture(
        captures_at(template_bufnr, template_lines, "gold"),
        "javascript",
        "argiope.unknown.template"
      )
    )
    assert.is_true(
      has_capture(
        captures_at(template_bufnr, template_lines, "${value}", 2),
        "javascript",
        "variable"
      )
    )

    local javascript = assert(
      require("argiope.palette").get(require("argiope.config").get_palettes("classic").javascript)
    )
    assert.are.equal(color(javascript.gray), highlight_color("@argiope.unknown.tag.javascript"))
    assert.are.equal(color(javascript.gray), highlight_color("@argiope.unknown.template.javascript"))
    assert.are.equal(
      color(javascript.gray_dim),
      highlight_color("@argiope.unknown.delimiter.javascript")
    )
  end)

  it("preserves the classic base and varied monochromatic JavaScript colors", function()
    local javascript = assert(
      require("argiope.palette").get(require("argiope.config").get_palettes("classic").javascript)
    )
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    assert.are.equal(color("#080A16"), normal.bg)
    assert.are.equal(color("#F8F8F2"), normal.fg)
    assert.are.equal("#C7B143", javascript.main)
    assert.are.equal(color(javascript.muted), highlight_color("@string.javascript"))
    assert.are.equal(color(javascript.gray_warm), highlight_color("@keyword.javascript"))
    assert.are.equal(color(javascript.gray), highlight_color("@keyword.import.javascript"))
    assert.are.equal(color(javascript.bright), highlight_color("@function.call.javascript"))
    assert.are.equal(color(javascript.main), highlight_color("@variable.javascript"))
    assert.are.equal(color(javascript.light), highlight_color("@variable.parameter.javascript"))
    assert.are.equal(color(javascript.soft), highlight_color("@property.javascript"))
    assert.are.equal(color(javascript.gray_dim), highlight_color("@comment.javascript"))
    assert.are.equal(color(javascript.gray), highlight_color("@punctuation.delimiter.javascript"))
    assert.are.equal(color(javascript.gray_dim), highlight_color("@punctuation.special.javascript"))
    assert.are.equal(
      color(javascript.gray_dim),
      highlight_color("@argiope.interpolation.delimiter.javascript")
    )

    local interpolation_captures = captures_at(bufnr, lines, "${title}")
    assert.is_true(has_capture(interpolation_captures, "javascript", "punctuation.special"))
    assert.is_true(
      has_capture(interpolation_captures, "javascript", "argiope.interpolation.delimiter")
    )
    local interpolation_close = captures_at(bufnr, lines, "${title}", #"${title}" - 1)
    assert.is_true(
      has_capture(interpolation_close, "javascript", "argiope.interpolation.delimiter")
    )
    local interpolation_value = captures_at(bufnr, lines, "${title}", 2)
    assert.is_true(has_capture(interpolation_value, "javascript", "variable"))
    local css_interpolation = captures_at(bufnr, lines, "${MYCLASS}", 2)
    assert.is_true(has_capture(css_interpolation, "javascript", "variable"))
  end)

  it("toggles JavaScript between monochrome and semantic colors without changing embedded languages", function()
    local argiope = require("argiope")
    local colors = require("argiope.palette")
    local defaults = require("argiope.config").get_palettes("classic")
    local javascript = assert(colors.get(defaults.javascript))
    local html_before = highlight_color("@tag.html")
    local css_before = highlight_color("@property.css")
    local markdown_before = highlight_color("@markup.heading.1.markdown")

    assert.are.equal("monochrome", argiope.get_theme_mode())
    assert.are.equal(color(javascript.muted), highlight_color("@string.javascript"))

    assert.are.equal("hybrid", argiope.toggle_theme())
    assert.are.equal(color(colors.base.string_gray), highlight_color("@string.javascript"))
    assert.are.equal(color(colors.base.pink), highlight_color("@keyword.javascript"))
    assert.are.equal(color(colors.base.green), highlight_color("@function.call.javascript"))
    assert.are.equal(color(colors.base.beige), highlight_color("@variable.javascript"))
    assert.are.equal(color(colors.base.purple), highlight_color("@number.javascript"))
    assert.are.equal(color(colors.base.fg), highlight_color("@punctuation.delimiter.javascript"))
    assert.are.equal(html_before, highlight_color("@tag.html"))
    assert.are.equal(css_before, highlight_color("@property.css"))
    assert.are.equal(markdown_before, highlight_color("@markup.heading.1.markdown"))

    assert.are.equal("monochrome", argiope.toggle_theme())
    assert.are.equal(color(javascript.muted), highlight_color("@string.javascript"))
  end)

  it("uses warm values, golden constants, and gray strings in hybrid JavaScript", function()
    local example = {
      "const { LIST, OPTION, CONTROL, COPY } = classify('CaptainUIChoice')",
      "",
      "function present(value) {",
      "  return JSON.stringify(value)",
      "}",
    }
    local example_bufnr = helpers.new_javascript_buffer(example)
    assert(vim.treesitter.get_parser(example_bufnr, "javascript"):parse(true))
    require("argiope").set_theme_mode("hybrid")

    assert.is_true(
      has_capture(captures_at(example_bufnr, example, "LIST"), "javascript", "constant")
    )
    assert.is_true(
      has_capture(captures_at(example_bufnr, example, "value"), "javascript", "variable.parameter")
    )
    assert.is_true(
      has_capture(captures_at(example_bufnr, example, "'CaptainUIChoice'", 1), "javascript", "string")
    )

    local colors = require("argiope.palette").base
    assert.are.equal(color(colors.golden_yellow), highlight_color("@constant.javascript"))
    assert.are.equal(color(colors.beige), highlight_color("@variable.javascript"))
    assert.are.equal(color(colors.beige), highlight_color("@variable.parameter.javascript"))
    assert.are.equal(color(colors.string_gray), highlight_color("@string.javascript"))
  end)

  it("rejects unknown theme modes without changing the active mode", function()
    local argiope = require("argiope")
    local ok, err = pcall(argiope.set_theme_mode, "rainbow")

    assert.is_false(ok)
    assert.matches("theme mode must be", tostring(err), 1, true)
    assert.are.equal("monochrome", argiope.get_theme_mode())
  end)

  it("keeps explicit language palette overrides across profiles", function()
    local argiope = require("argiope")
    argiope.setup({
      palettes = { html = "pink" },
      theme = {
        palettes = {
          day = { html = "blue" },
        },
      },
    })

    assert.are.equal("contrast", argiope.set_theme_variant("contrast"))
    assert.are.equal("contrast", argiope.get_theme_variant())
    assert.are.equal("dark", vim.o.background)
    assert.are.equal(
      color(require("argiope.palette").get("pink").main),
      highlight_color("@tag.html")
    )

    assert.are.equal("day", argiope.set_theme_variant("day"))
    assert.are.equal("light", vim.o.background)
    assert.are.equal(
      color(require("argiope.palette").get("blue").main),
      highlight_color("@tag.html")
    )
  end)

  it("uses profile language defaults for classic, quiet, and day", function()
    local config = require("argiope.config")

    assert.are.equal("gold2", config.get_palettes("classic").javascript)
    assert.are.equal("gold2", config.get_palettes("contrast").javascript)
    assert.are.equal("gray", config.get_palettes("quiet").javascript)
    assert.are.equal("gray", config.get_palettes("quiet").javascript_embedded)
    assert.are.equal("gray", config.get_palettes("day").javascript)
    assert.are.equal("gray", config.get_palettes("day").javascript_embedded)
    assert.are.equal("cyan", config.get_palettes("quiet").html)
    assert.are.equal("green", config.get_palettes("day").css)
    assert.are.equal("blush", config.get_palettes("day").markdown)
  end)

  it("keeps normal shade mapping with gray JavaScript in quiet mode", function()
    local argiope = require("argiope")
    argiope.set_theme_variant("quiet")
    local palettes = require("argiope.palette")
    local javascript = palettes.get("gray")
    local quiet_gray = palettes.hsl.monochrome.gray

    assert.are.equal(color(javascript.main), highlight_color("@variable.javascript"))
    assert.are.equal(color(javascript.gray_warm), highlight_color("@keyword.javascript"))
    assert.are.equal(
      color(javascript.gray),
      highlight_color("@punctuation.delimiter.javascript")
    )
    for _, family in ipairs({ "cyan", "green", "blush" }) do
      local quiet_embedded = palettes.hsl.monochrome[family]
      local contrast_embedded = palettes.profiles.contrast.hsl[family]
      assert.is_true(quiet_embedded.main.saturation > quiet_gray.main.saturation)
      assert.is_true(quiet_embedded.main.saturation < contrast_embedded.main.saturation)
    end
  end)

  it("uses gray JavaScript and dark fully saturated embedded colors in day mode", function()
    require("argiope").set_theme_variant("day")
    local day = require("argiope.palette")
    local javascript = day.hsl.monochrome.gray

    assert.are.equal("light", vim.o.background)
    assert.are.equal(color(day.monochrome.gray.main), highlight_color("@variable.javascript"))
    for _, family in ipairs({ "cyan", "green", "blush" }) do
      local embedded = day.hsl.monochrome[family]
      assert.are.equal(100, embedded.main.saturation)
      assert.is_true(embedded.main.lightness < 50)
      assert.is_true(embedded.main.saturation > javascript.main.saturation)
    end
    assert.are.equal("#AD0000", day.base.red)
  end)

  it("rejects unknown theme variants without changing the active variant", function()
    local argiope = require("argiope")
    local before = argiope.get_theme_variant()
    local ok, err = pcall(argiope.set_theme_variant, "ultraviolet")

    assert.is_false(ok)
    assert.matches("theme variant must be", tostring(err), 1, true)
    assert.are.equal(before, argiope.get_theme_variant())
  end)

  it("maps HTML, CSS, and Markdown to their configured default palettes", function()
    local defaults = require("argiope.config").get_palettes("classic")
    local palettes = require("argiope.palette")
    local html = assert(palettes.get(defaults.html))
    local css = assert(palettes.get(defaults.css))
    local markdown = assert(palettes.get(defaults.markdown))

    assert.are.equal(color(html.main), highlight_color("@tag.html"))
    assert.are.equal(color(html.light), highlight_color("@string.html"))
    assert.are.equal(color(css.main), highlight_color("@property.css"))
    assert.are.equal(color(css.accent), highlight_color("@number.css"))
    assert.are.equal(color(markdown.accent), highlight_color("@markup.heading.1.markdown"))
    assert.are.equal(color(markdown.main), highlight_color("@markup.link.markdown_inline"))
  end)

  it("uses the configured Markdown palette for normal prose", function()
    local markdown = require("argiope.palette").get(
      require("argiope.config").get_palettes("classic").markdown
    )
    assert.are.equal(color(markdown.gray), highlight_color("@spell.markdown"))
  end)

  it("provides readable Snacks Explorer highlight groups", function()
    local colors = require("argiope.palette").base
    assert.are.equal(color(colors.fg), highlight_color("SnacksPickerFile"))
    assert.are.equal(color(colors.cyan), highlight_color("SnacksPickerDirectory"))
    assert.are.equal(color(colors.orange), highlight_color("SnacksPickerGitStatusUntracked"))
    assert.are.equal(color(colors.gutter_fg), highlight_color("SnacksPickerTree"))
  end)

  it("honors configured embedded-language palettes", function()
    require("argiope").setup({
      palettes = {
        html = "pink",
        javascript_embedded = "blue",
      },
    })
    require("argiope.theme").apply()

    assert.are.equal(color("#C3418D"), highlight_color("@tag.html"))
    assert.are.equal(color("#543647"), highlight_color("@tag.delimiter.html"))
    assert.are.equal(
      color("#4182C3"),
      highlight_color("@variable.argiope_javascript")
    )
  end)

  it("keeps every monochrome palette structurally interchangeable", function()
    local palettes = require("argiope.palette").monochrome
    local expected = vim.tbl_keys(palettes.gold)
    table.sort(expected)

    assert.are.equal(12, #expected)
    local palette_names = {
      "blue",
      "green",
      "gold",
      "gold2",
      "gray",
      "indigo",
      "violet",
      "blush",
      "pink",
      "cyan",
    }
    assert.are.equal(10, #palette_names)
    for _, palette_name in ipairs(palette_names) do
      local actual = vim.tbl_keys(palettes[palette_name])
      table.sort(actual)
      assert.are.same(expected, actual)

      require("argiope").setup({
        palettes = {
          javascript = palette_name,
          html = palette_name,
          css = palette_name,
          markdown = palette_name,
        },
      })
      assert.has_no.errors(function()
        require("argiope.theme").apply()
      end)
      assert.are.equal(
        color(palettes[palette_name].gray_dim),
        highlight_color("@argiope.interpolation.delimiter.javascript")
      )
    end

    assert.are_not.same(palettes.gold, palettes.gold2)
  end)
end)
