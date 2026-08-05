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

  it("emits family-scoped hue variables and a shared shade ladder", function()
    local css = require("argiope.render").css()

    assert.is_truthy(css:find('.a.h,.a .h{--a-h:185;--a-gh:190;', 1, true))
    assert.is_truthy(css:find('.a .l0{color:hsl(calc(var(--a-h)', 1, true))
    assert.is_truthy(css:find('.a .h .l0{color:hsl(calc(var(--a-h)', 1, true))
    assert.is_truthy(css:find(".a.g,.a.k{--a-g0:", 1, true))
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

    assert.is_truthy(html:find('<pre class="a r lang-lua"><code>', 1, true))
    assert.is_truthy(html:find('class="l', 1, true))
    assert.is_truthy(css:find(".a.r{--a-h:27;--a-gh:32;", 1, true))
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
