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

  it("emits family-scoped hue variables and compact semantic tones", function()
    local css = require("argiope.render").css()
    local palettes = require("argiope.palette")
    local html = palettes.hsl.monochrome[
      require("argiope.config").get_palettes("classic").html
    ]

    assert.is_truthy(css:find((
      '.a.h,.a .h{--a-h:%d;--a-gh:%d;'
    ):format(html.main.hue, html.gray.hue), 1, true))
    assert.is_truthy(css:find('.a .t0{color:hsl(calc(var(--a-h)', 1, true))
    assert.is_truthy(css:find('.a .h .t0{color:hsl(calc(var(--a-h)', 1, true))
    assert.is_truthy(css:find('.a .t12{color:hsl(calc(var(--a-gh)', 1, true))
    assert.is_truthy(css:find(".a.g,.a.k{--a-g0:", 1, true))
  end)

  it("keeps semantic HTML stable while profiles reinterpret comments", function()
    local renderer = require("argiope.render")
    local source = [[// host
const card = html`<!-- html -->`
const styles = css`/* css */`]]
    local argiope = require("argiope")
    argiope.set_theme_variant("contrast")
    local night = renderer.html(source)
    local day_css = renderer.css({ variant = "day" })
    assert.are.equal("contrast", argiope.get_theme_variant())
    argiope.set_theme_variant("day")
    local day = renderer.html(source)

    assert.are.equal(night, day)
    assert.is_truthy(day:find('class="t12 i"', 1, true))
    assert.is_truthy(day_css:find(".a .t12{color:hsl(0 0% 61%)}", 1, true))
  end)

  it("can select a CSS profile without changing the active theme", function()
    local argiope = require("argiope")
    local renderer = require("argiope.render")
    argiope.set_theme_variant("classic")

    local classic = renderer.css({ variant = "classic" })
    local day = renderer.css({ variant = "day" })
    local profiles = require("argiope.palette").profiles

    assert.not_equal(classic, day)
    assert.is_truthy(classic:find("--a-bg:" .. profiles.classic.base.bg, 1, true))
    assert.is_truthy(day:find("--a-bg:" .. profiles.day.base.bg, 1, true))
    assert.are.equal("classic", argiope.get_theme_variant())
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
    assert.is_truthy(html:find("&lt;main", 1, true))
    assert.is_truthy(html:find('class="g', 1, true))
  end)

  it("can render host JavaScript with Argiope's hybrid mode", function()
    local html = require("argiope.render").html([[const card = html`<article>${title}</article>`]], {
      mode = "hybrid",
    })

    assert.is_truthy(html:find('<pre class="a j k lang-javascript"><code>', 1, true))
    assert.is_truthy(html:find('class="g', 1, true))
    assert.is_truthy(html:find('<span class="h">', 1, true))
  end)

  it("can apply selected monochrome palettes to other Tree-sitter languages", function()
    local renderer = require("argiope.render")
    local html = renderer.html('local answer = 42', {
      language = "lua", palette = "ember",
    })
    local css = require("argiope.render").css()
    local ember = require("argiope.palette").hsl.monochrome.ember

    assert.is_truthy(html:find('<pre class="a r lang-lua"><code>', 1, true))
    assert.is_truthy(html:find('class="t', 1, true))
    assert.is_truthy(css:find((".a.r{--a-h:%d;--a-gh:%d;"):format(
      ember.main.hue,
      ember.gray.hue
    ), 1, true))
    assert.is_truthy(renderer.html('echo hello', {
      language = "bash", palette = "slate",
    }):find('<pre class="a s lang-bash"><code>', 1, true))
    assert.is_truthy(renderer.html('{"ok": true}', {
      language = "json", palette = "indigo",
    }):find('<pre class="a q lang-json"><code>', 1, true))
    assert.is_truthy(renderer.html('<main>hello</main>', {
      language = "html", palette = "html",
    }):find('<pre class="a h lang-html"><code>', 1, true))
  end)
end)
