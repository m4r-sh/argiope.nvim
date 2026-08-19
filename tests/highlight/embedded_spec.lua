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

local function language(name, variant)
  return assert(require("argiope.palette").profile(variant or "aurantia").languages[name])
end

local function role_color(definition, role)
  return definition.colors[definition.roles[role]]
end

describe("embedded language highlighting", function()
  local lines
  local bufnr

  before_each(function()
    require("argiope").setup()
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

  it("lets the normal UI cycle redraw after rebuilding normalized spans", function()
    local redraw = vim.cmd.redraw
    local redraws = 0
    vim.cmd.redraw = function()
      redraws = redraws + 1
    end

    vim.api.nvim_buf_set_lines(bufnr, 1, 2, false, { "  <article>updated</article>" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = bufnr })
    vim.wait(50)
    vim.cmd.redraw = redraw

    assert.are.equal(0, redraws)
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
    local embedded = language("javascript_embedded").colors
    assert.are.equal(
      color(embedded.main),
      highlight_color("@variable.argiope_javascript")
    )

    require("argiope").set_theme_variant("versicolor")
    assert.are.equal(
      color(palettes.base.beige),
      highlight_color("@variable.javascript")
    )
    assert.are.equal(
      color(embedded.main),
      highlight_color("@variable.argiope_javascript")
    )
    require("argiope").set_theme_variant("aurantia")
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

    local javascript = language("javascript").colors
    assert.are.equal(color(javascript.gray), highlight_color("@argiope.unknown.tag.javascript"))
    assert.are.equal(color(javascript.gray), highlight_color("@argiope.unknown.template.javascript"))
    assert.are.equal(
      color(javascript.gray_dim),
      highlight_color("@argiope.unknown.delimiter.javascript")
    )
  end)

  it("preserves the Aurantia base and varied monochromatic JavaScript colors", function()
    local javascript = language("javascript").colors
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    assert.are.equal(color("#080A16"), normal.bg)
    assert.are.equal(color("#F8F8F2"), normal.fg)
    assert.are.equal("#C19945", javascript.main)
    local definition = language("javascript")
    assert.are.equal(color(role_color(definition, "string")), highlight_color("@string.javascript"))
    assert.are.equal(color(role_color(definition, "keyword")), highlight_color("@keyword.javascript"))
    assert.are.equal(color(role_color(definition, "keyword")), highlight_color("@keyword.import.javascript"))
    assert.are.equal(color(role_color(definition, "call")), highlight_color("@function.call.javascript"))
    assert.are.equal(color(role_color(definition, "variable")), highlight_color("@variable.javascript"))
    assert.are.equal(color(role_color(definition, "variable")), highlight_color("@variable.parameter.javascript"))
    assert.are.equal(color(role_color(definition, "property")), highlight_color("@property.javascript"))
    assert.are.equal(color(role_color(definition, "comment")), highlight_color("@comment.javascript"))
    assert.are.equal(color(role_color(definition, "punctuation")), highlight_color("@punctuation.delimiter.javascript"))
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

  it("switches between Aurantia and Versicolor without changing embedded languages", function()
    local argiope = require("argiope")
    local colors = require("argiope.palette")
    local javascript = language("javascript").colors
    local html_before = highlight_color("@tag.html")
    local css_before = highlight_color("@property.css")
    local markdown_before = highlight_color("@markup.heading.1.markdown")

    assert.are.equal(color(role_color(language("javascript"), "string")), highlight_color("@string.javascript"))

    assert.are.equal("versicolor", argiope.set_theme_variant("versicolor"))
    assert.are.equal(color(colors.base.string_gray), highlight_color("@string.javascript"))
    assert.are.equal(color(colors.base.pink), highlight_color("@keyword.javascript"))
    assert.are.equal(color(colors.base.green), highlight_color("@function.call.javascript"))
    assert.are.equal(color(colors.base.beige), highlight_color("@variable.javascript"))
    assert.are.equal(color(colors.base.purple), highlight_color("@number.javascript"))
    assert.are.equal(color(colors.base.fg), highlight_color("@punctuation.delimiter.javascript"))
    assert.are.equal(html_before, highlight_color("@tag.html"))
    assert.are.equal(css_before, highlight_color("@property.css"))
    assert.are.equal(markdown_before, highlight_color("@markup.heading.1.markdown"))

    assert.are.equal("aurantia", argiope.set_theme_variant("aurantia"))
    assert.are.equal(color(role_color(language("javascript"), "string")), highlight_color("@string.javascript"))
  end)

  it("uses warm values, golden constants, and gray strings in Versicolor", function()
    local example = {
      "const { LIST, OPTION, CONTROL, COPY } = classify('CaptainUIChoice')",
      "",
      "function present(value) {",
      "  return JSON.stringify(value)",
      "}",
    }
    local example_bufnr = helpers.new_javascript_buffer(example)
    assert(vim.treesitter.get_parser(example_bufnr, "javascript"):parse(true))
    require("argiope").set_theme_variant("versicolor")

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

  it("applies inherited user theme language overrides", function()
    local argiope = require("argiope")
    argiope.setup({
      theme = {
        variant = "custom",
        definitions = {
          custom = {
            extends = "aurantia",
            name = "Custom",
            languages = {
              html = {
                colors = { main = "#C3418D", darkest = "#543647" },
                roles = { type = "main" },
              },
              javascript_embedded = {
                colors = { main = "#4182C3" },
                roles = { variable = "main" },
              },
            },
          },
        },
      },
    })
    require("argiope.theme").apply()

    assert.are.equal("custom", argiope.get_theme_variant())
    assert.are.equal("dark", vim.o.background)
    assert.are.equal(color("#C3418D"), highlight_color("@tag.html"))
    assert.are.equal(color("#543647"), highlight_color("@tag.delimiter.html"))
    assert.are.equal(color("#4182C3"), highlight_color("@variable.argiope_javascript"))
  end)

  it("exposes generated language defaults for every built-in", function()
    local profiles = require("argiope.palette").profiles

    for _, profile in pairs(profiles) do
      for _, name in ipairs({ "javascript", "javascript_embedded", "html", "css", "markdown" }) do
        assert.is_table(profile.languages[name].colors)
        assert.is_table(profile.languages[name].roles)
      end
    end
    assert.are.equal("Argiope Aurantia", profiles.aurantia.name)
    assert.are.equal("Argiope Versicolor", profiles.versicolor.name)
    assert.are.equal("Argiope Aurantia Neon", profiles["aurantia-neon"].name)
    assert.are.equal("Argiope Versicolor Neon", profiles["versicolor-neon"].name)
    assert.are.equal("Argiope Ocyaloides", profiles.ocyaloides.name)
    assert.are.equal("Argiope Trifasciata", profiles.trifasciata.name)
  end)

  it("exposes every profile as an Argiope-prefixed colorscheme", function()
    for _, id in ipairs(require("argiope.palette").variants()) do
      vim.cmd.colorscheme("argiope-" .. id)
      assert.are.equal(id, require("argiope").get_theme_variant())
      assert.are.equal("argiope-" .. id, vim.g.colors_name)
    end
  end)

  it("uses the generated neutral JavaScript colors in Ocyaloides", function()
    local argiope = require("argiope")
    argiope.set_theme_variant("ocyaloides")
    local javascript = language("javascript", "ocyaloides")

    assert.are.equal(color(role_color(javascript, "variable")), highlight_color("@variable.javascript"))
    assert.are.equal(color(role_color(javascript, "keyword")), highlight_color("@keyword.javascript"))
    assert.are.equal(
      color(role_color(javascript, "punctuation")),
      highlight_color("@punctuation.delimiter.javascript")
    )
  end)

  it("uses a generated neutral JavaScript ramp in Trifasciata", function()
    require("argiope").set_theme_variant("trifasciata")
    local trifasciata = require("argiope.palette").profile("trifasciata")
    local javascript = trifasciata.languages.javascript

    assert.are.equal("light", vim.o.background)
    assert.are.equal(color(role_color(javascript, "variable")), highlight_color("@variable.javascript"))
    assert.are.equal(color(role_color(javascript, "punctuation")), highlight_color("@punctuation.delimiter.javascript"))

    local comment = color("#9C9C9C")
    assert.are.equal(comment, highlight_color("Comment"))
    for _, group in ipairs({
      "@comment.javascript",
      "@comment.argiope_javascript",
      "@comment.html",
      "@comment.css",
    }) do
      assert.is_number(highlight_color(group))
    end
  end)

  it("uses generated HTML and CSS colors in Trifasciata", function()
    require("argiope").set_theme_variant("trifasciata")
    local trifasciata = require("argiope.palette").profile("trifasciata")

    assert.are.equal(color(role_color(trifasciata.languages.html, "type")), highlight_color("@tag.html"))
    assert.are.equal(color(role_color(trifasciata.languages.css, "property")), highlight_color("@property.css"))
    assert.are.equal("#AD0000", trifasciata.base.red)
  end)

  it("uses a high-contrast block cursor in Trifasciata", function()
    local argiope = require("argiope")
    argiope.set_theme_variant("trifasciata")
    local colors = require("argiope.palette").base

    for _, group in ipairs({ "Cursor", "lCursor", "CursorIM", "TermCursor" }) do
      local cursor = vim.api.nvim_get_hl(0, { name = group, link = false })
      assert.are.equal(color(colors.cursor), cursor.bg)
      assert.are.equal(color(colors.bg), cursor.fg)
    end
    assert.are.equal("#FAEB42", colors.cursor)

    local visual = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
    assert.are.equal("#F9F3B4", colors.visual_selection)
    assert.are.equal(color(colors.visual_selection), visual.bg)

    assert.is_truthy(vim.o.guicursor:find(
      "n-v-c-sm:block-ArgiopeLightCursor",
      1,
      true
    ))
    argiope.set_theme_variant("aurantia")
    assert.is_falsy(vim.o.guicursor:find("ArgiopeLightCursor", 1, true))
  end)

  it("rejects unknown theme variants without changing the active variant", function()
    local argiope = require("argiope")
    local before = argiope.get_theme_variant()
    local ok, err = pcall(argiope.set_theme_variant, "ultraviolet")

    assert.is_false(ok)
    assert.matches("unknown theme variant", tostring(err), 1, true)
    assert.are.equal(before, argiope.get_theme_variant())
  end)

  it("maps HTML, CSS, and Markdown to generated language colors", function()
    local html = language("html")
    local css = language("css")
    local markdown = language("markdown")

    assert.are.equal(color(html.colors.main), highlight_color("@tag.html"))
    assert.are.equal(color(role_color(html, "string")), highlight_color("@string.html"))
    assert.are.equal(color(role_color(css, "property")), highlight_color("@property.css"))
    assert.are.equal(color(role_color(css, "number")), highlight_color("@number.css"))
    assert.are.equal(color(markdown.colors.accent), highlight_color("@markup.heading.1.markdown"))
    assert.are.equal(color(markdown.colors.main), highlight_color("@markup.link.markdown_inline"))
  end)

  it("uses the generated Markdown palette for normal prose", function()
    assert.are.equal(color(language("markdown").colors.gray), highlight_color("@spell.markdown"))
  end)

  it("provides readable Snacks Explorer highlight groups", function()
    local colors = require("argiope.palette").base
    assert.are.equal(color(colors.fg), highlight_color("SnacksPickerFile"))
    assert.are.equal(color(colors.cyan), highlight_color("SnacksPickerDirectory"))
    assert.are.equal(color(colors.orange), highlight_color("SnacksPickerGitStatusUntracked"))
    assert.are.equal(color(colors.gutter_fg), highlight_color("SnacksPickerTree"))
  end)

  it("keeps every generated language ramp structurally interchangeable", function()
    local profiles = require("argiope.palette").profiles
    local expected = vim.tbl_keys(profiles.aurantia.languages.javascript.colors)
    table.sort(expected)

    assert.are.equal(12, #expected)
    for _, profile in pairs(profiles) do
      for _, definition in pairs(profile.languages) do
        local actual = vim.tbl_keys(definition.colors)
        table.sort(actual)
        assert.are.same(expected, actual)
      end
    end
  end)
end)
