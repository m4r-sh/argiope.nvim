describe("HTML rendering", function()
  before_each(function()
    require("argiope").setup()
  end)

  it("uses Argiope's normalized tagged-template captures in compact markup", function()
    local rendered = require("argiope.render").render([[const card = html`
  <article class="${kind}">${title}</article>
`
const styles = css`article { color: var(--ink); }`]])

    assert.is_truthy(rendered.html:find('<pre class="a j lang-javascript"><code>', 1, true))
    assert.is_truthy(rendered.html:find('<span class="h">', 1, true))
    assert.is_truthy(rendered.html:find("&lt;", 1, true))
    assert.is_truthy(rendered.html:find("article", 1, true))
    assert.is_truthy(rendered.html:find('<span class="c">', 1, true))
    assert.is_truthy(rendered.html:find("kind", 1, true))
  end)

  it("emits family-scoped color variables and compact semantic tones", function()
    local css = require("argiope.render").css()

    assert.is_truthy(css:find('.a.h,.a .h{--a-t0:#', 1, true))
    assert.is_truthy(css:find('.a.s,.a .s{--a-t0:#', 1, true))
    assert.is_truthy(css:find('.a.l,.a .l{--a-t0:#', 1, true))
    assert.is_truthy(css:find('.a.w,.a .w{--a-t0:#', 1, true))
    assert.is_truthy(css:find('.a .t0{color:var(--a-t0)}', 1, true))
    assert.is_truthy(css:find('.a .t12{color:var(--a-t12)}', 1, true))
    assert.is_truthy(css:find(".a.g,.a.k{--a-g0:", 1, true))
  end)

  it("keeps semantic HTML stable while profiles reinterpret comments", function()
    local renderer = require("argiope.render")
    local source = [[// host
const card = html`<!-- html -->`
const styles = css`/* css */`]]
    local argiope = require("argiope")
    argiope.set_theme_variant("aurantia")
    local night = renderer.html(source)
    local light_css = renderer.css({ variant = "trifasciata" })
    assert.are.equal("aurantia", argiope.get_theme_variant())
    argiope.set_theme_variant("trifasciata")
    local light = renderer.html(source)

    assert.are.equal(night, light)
    assert.is_truthy(light:find('class="t16 i"', 1, true))
    assert.is_truthy(light_css:find("--a-t12:#", 1, true))
  end)

  it("can select a CSS profile without changing the active theme", function()
    local argiope = require("argiope")
    local renderer = require("argiope.render")
    argiope.set_theme_variant("aurantia")

    local aurantia = renderer.css({ variant = "aurantia" })
    local trifasciata = renderer.css({ variant = "trifasciata" })
    local profiles = require("argiope.palette").profiles

    assert.not_equal(aurantia, trifasciata)
    assert.is_truthy(aurantia:find("--a-bg:" .. profiles.aurantia.base.bg, 1, true))
    assert.is_truthy(trifasciata:find("--a-bg:" .. profiles.trifasciata.base.bg, 1, true))
    assert.are.equal("aurantia", argiope.get_theme_variant())
    assert.has_error(function()
      renderer.css({ variant = "ultraviolet" })
    end, 'argiope.render: unknown theme variant "ultraviolet"')
  end)

  it("uses Neovim's native query and injection pipeline for other languages", function()
    local html = require("argiope.render").html(
      '<main><style>main { color: red; }</style><script>const ok = true</script></main>',
      { language = "html" }
    )

    assert.is_truthy(html:find('<pre class="a g lang-html"><code>', 1, true))
    assert.is_truthy(html:find("main", 1, true))
    assert.is_truthy(html:find('class="g', 1, true))
  end)

  it("renders the explicit Versicolor palette through ordinary ramp tones", function()
    local html = require("argiope.render").html([[const card = html`<article>${title}</article>`]], {
      variant = "versicolor",
    })

    assert.is_truthy(html:find('<pre class="a j lang-javascript"><code>', 1, true))
    assert.is_truthy(html:find('class="t', 1, true))
    assert.is_truthy(html:find('<span class="h">', 1, true))
  end)

  it("can apply generated language palettes to other Tree-sitter languages", function()
    local renderer = require("argiope.render")
    local html = renderer.html('local answer = 42', {
      language = "lua", palette = "css",
    })
    local css = require("argiope.render").css()

    assert.is_truthy(html:find('<pre class="a c lang-lua"><code>', 1, true))
    assert.is_truthy(html:find('class="t', 1, true))
    assert.is_truthy(renderer.html('echo hello', {
      language = "bash", palette = "markdown",
    }):find('<pre class="a m lang-bash"><code>', 1, true))
    assert.is_truthy(renderer.html('{"ok": true}', {
      language = "json", palette = "javascript_embedded",
    }):find('<pre class="a e lang-json"><code>', 1, true))
    assert.is_truthy(renderer.html('<main>hello</main>', {
      language = "html", palette = "html",
    }):find('<pre class="a h lang-html"><code>', 1, true))
    assert.is_truthy(renderer.html('<circle cx="4"/>', {
      language = "html", palette = "svg",
    }):find('<pre class="a s lang-html"><code>', 1, true))
  end)
end)

describe("semantic rendering API", function()
  it("exposes contiguous UTF-8 byte ranges and stable roles", function()
    require("argiope").setup()
    local renderer = require("argiope.render")
    local source = 'const { TITLE, BUTTON } = classify("é<&"); // end'
    local document = renderer.tokenize(source)
    local cursor, joined, bindings = 0, {}, 0
    for _, segment in ipairs(document.segments) do
      assert.are.equal(cursor, segment.start)
      assert.are.equal(source:sub(segment.start + 1, segment.finish), segment.text)
      cursor = segment.finish
      table.insert(joined, segment.text)
      if segment.text == "TITLE" or segment.text == "BUTTON" then
        assert.are.equal("const_binding", segment.role)
        bindings = bindings + 1
      end
    end
    assert.are.equal(2, bindings)
    assert.are.equal(#source, cursor)
    assert.are.equal(source, table.concat(joined))
    assert.are.equal(renderer.html(source), renderer.to_html(document))
    assert.is_truthy(renderer.to_html(document):find("&lt;&amp;", 1, true))
  end)

  it("resolves role CSS to the same colors as Neovim for all built-ins", function()
    local theme = require("argiope.theme")
    local renderer = require("argiope.render")
    for variant in pairs(require("argiope.palette").profiles) do
      require("argiope").set_theme_variant(variant)
      vim.cmd.colorscheme("argiope-" .. variant)
      local css = renderer.css({ variant = variant })
      for capture, role in pairs({ variable = "variable", string = "string", number = "number",
        ["function.builtin"] = "builtin", ["function.call"] = "call",
        ["function.method.call"] = "method_call", ["argiope.const.variable"] = "const_binding" }) do
        local highlight = vim.api.nvim_get_hl(0, { name = "@" .. capture .. ".javascript", link = false })
        local expected = string.format("#%06X", highlight.fg)
        assert.are.equal(expected, theme.role_color("javascript", role, variant):upper())
        local index
        for i, name in ipairs(theme.roles) do if name == role then index = i - 1 end end
        assert.is_truthy(css:upper():find("--A-T" .. index .. ":" .. expected, 1, true))
      end
    end
  end)

  it("does not confuse SVG family with strikethrough", function()
    local css = require("argiope.render").css()
    assert.is_nil(css:find(".a .s{text-decoration", 1, true))
    assert.is_truthy(css:find(".a .strike{text-decoration", 1, true))
  end)
end)
