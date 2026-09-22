# argiope.nvim

Argiope gives each embedded language its own color family: HTML, CSS, Markdown, SVG, JavaScript, GLSL, and WGSL stay visually distinct inside JavaScript templates. It also supplies a complete editor theme, readable generic syntax colors for other languages, and optional editing helpers.

[Blog Post](https://m4rsh.com/argiope)

[Palettes](https://github.com/m4r-sh/argiope)

---

**Primary Features**

- Tree-sitter HTML, SVG, CSS, Markdown, JavaScript, GLSL, and WGSL injections
- Embedded-language-aware indentation, substitutions, and comments
- A number of syntax highlighting themes

---

## Quick start

Requires **Neovim 0.12+**. For just the themes, no parser manager is required:

```lua
vim.pack.add({ "https://github.com/m4r-sh/argiope.nvim" })
require("argiope").setup()
vim.cmd.colorscheme("argiope-aurantia")
```

Existing Vim syntax highlighting gets generic colors. If a Tree-sitter parser
and highlight queries are installed, Argiope starts them automatically for
normal file buffers. Missing parsers do not prevent the theme from loading.

For tagged templates and language-aware indentation, add the parser packages
before Argiope:

```lua
vim.pack.add({
  "https://github.com/neovim-treesitter/treesitter-parser-registry",
  "https://github.com/neovim-treesitter/nvim-treesitter",
  "https://github.com/m4r-sh/argiope.nvim",
})
require("argiope").setup()
vim.cmd.colorscheme("argiope-aurantia")
```

Install the web parsers and inherited queries once, then restart Neovim:

```vim
:lua require("nvim-treesitter").install({ "javascript", "html", "css", "markdown", "markdown_inline", "ecma", "jsx", "html_tags" }):wait(300000)
```

Install other languages as needed, for example:

```vim
:lua require("nvim-treesitter").install({ "lua", "python", "glsl", "wgsl" }):wait(300000)
```

Parser installation uses nvim-treesitter's compiler/download requirements.
Use `:TSUpdate` after updating nvim-treesitter, and `:checkhealth argiope`
when a language does not highlight. Shader parsers are optional; SVG uses HTML.

## Language colors

Unlisted languages use ordinary semantic colors. The predefined families keep
Argiope's distinctive coloring. Override only the assignments you want:

```lua
require("argiope").setup({
  highlight = {
    languages = {
      css = false,          -- generic colors, parsing still enabled
      lua = "javascript",   -- Lua syntax in the JavaScript color family
      embedded = "css",     -- raw.js templates in the CSS family
    },
  },
})
```

Use `true` for the language's predefined palette, `false` for generic colors,
or a family name to reuse its colors. Families are `javascript`, `embedded`,
`html`, `svg`, `css`, `markdown`, `glsl`, and `wgsl`. Other keys are Tree-sitter
parser names, such as `lua` or `python`; they require an installed parser and
queries. A palette assignment never changes which parser reads the code.
`markdown` controls both Markdown parsers, and `html` controls native and
embedded HTML. The underlying theme-definition key for `embedded` remains
`javascript_embedded` for compatibility.

Change assignments live:

```vim
:ArgiopeLanguage
:ArgiopeLanguage toggle css
:ArgiopeLanguage set lua javascript
:ArgiopeLanguage set html false
:ArgiopeLanguage reset css
```

The command without arguments opens a language picker. Runtime changes apply
across buffers, survive theme switches, and last until `setup()` or restart.
`reset` restores the assignment from setup. Toggling an unassigned language on
uses the JavaScript family. Lua equivalents are `set_language(name, value)`
and `toggle_language(name)`.

If another plugin starts Tree-sitter, set `highlight.auto_start = false` to
limit automatic attachment to the listed `filetypes`. Set
`highlight.enabled = false` to stop Argiope from starting highlighting at all.
A highlighter started by another plugin is left running on detach.
`filetypes = { python = false }` excludes a filetype from Argiope attachment;
it does not change the colorscheme's language assignments.

### Keep your existing colorscheme

Editing support works with other themes. To add Argiope's language colors on
top of another theme, enable the overlay:

```lua
vim.cmd.colorscheme("your-theme")
require("argiope").setup({
  theme = { variant = "aurantia", overlay = true },
  highlight = { languages = { javascript = false } },
})
```

The overlay preserves the editor background, UI colors, and generic syntax
colors. Disabled families keep the other theme's highlighting. Argiope
refreshes the overlay when you switch colorschemes. Leave `overlay = false`
(the default) to use just the editing support with another theme.

## Configuration

Calling `setup()` is optional when using the defaults. The complete default
configuration is:

```lua
require("argiope").setup({
  enabled = true,
  filetypes = {
    css = true,
    glsl = true,
    html = true,
    javascript = true,
    markdown = true,
    wgsl = true,
  },
  tags = {
    css = "css",
    glsl = "glsl",
    html = "html",
    md = "markdown",
    ["raw.js"] = "javascript",
    svg = "svg",
    wgsl = "wgsl",
  },
  indent = {
    enabled = true,
    shiftwidth = 2,
    expandtab = true,
  },
  authoring = {
    auto_close_tags = true,
  },
  highlight = {
    enabled = true,
    auto_start = true,
    languages = {},
  },
  join = {
    enabled = true,
  },
  theme = {
    variant = "aurantia",
    overlay = false,
    definitions = {},
  },
})
```

`tags` maps JavaScript tag spellings to `html`, `svg`, `css`, `javascript`,
`markdown`, `glsl`, or `wgsl`. Exact member-expression tags such as the default `raw.js` entry
are supported. Bare names also match the final property of a member
expression, so adding `prose = "markdown"` enables both `prose\`...\`` and
`ui.prose\`...\``.

Argiope starts native Tree-sitter highlighting for enabled HTML, CSS,
Markdown, GLSL, and WGSL buffers. They use the same language palettes as their
embedded counterparts. Markdown keeps its normal indentation outside fenced
code, while JavaScript fences use Argiope's tagged-template indentation.
Tagged-template joining and automatic HTML/SVG tag closing remain
JavaScript-buffer features.

With `authoring.auto_close_tags` enabled, pressing Enter immediately after a
parsed opening HTML or SVG tag inserts its closing tag, leaves the closing tag
aligned with the opener, and places the cursor in the indented body. Existing
insert-mode `<CR>` mappings are left untouched.

Set `enabled = false` to disable the plugin globally, or disable indentation,
highlighting, and joining independently. `shiftwidth = 0` uses the buffer's
existing `shiftwidth` (falling back to `tabstop`).

## Colorscheme

Argiope's editing support works with the user's existing colorscheme. The six
bundled themes are exposed with an `argiope-` prefix, so they group together in
editor theme lists:

```lua
vim.cmd.colorscheme("argiope-aurantia")
vim.cmd.colorscheme("argiope-versicolor-neon")
```

`colorscheme argiope` remains a configurable alias that loads the `theme.variant`
selected in `setup()`.

Embedded HTML, SVG, CSS, Markdown, JavaScript, GLSL, and WGSL use separately configurable hue
families. Six complete profiles are available. Their editor-facing names use
an `Argiope` prefix for alphabetical grouping, while configuration uses the
lowercase IDs below. Their resolved colors are generated by the standalone
`argiope` authoring project and vendored as Lua; this plugin performs
no runtime color generation.

The built-in assignments are:

| ID | Display name | Character |
| --- | --- | --- |
| `aurantia` | Argiope Aurantia | Original dark palette with monochromatic gold JavaScript |
| `versicolor` | Argiope Versicolor | Aurantia with multicolored semantic JavaScript |
| `aurantia-neon` | Argiope Aurantia Neon | Higher-contrast monochromatic JavaScript |
| `versicolor-neon` | Argiope Versicolor Neon | Higher contrast with multicolored semantic JavaScript |
| `ocyaloides` | Argiope Ocyaloides | Quiet, lower-saturation dark palette |
| `trifasciata` | Argiope Trifasciata | Light palette with neutral JavaScript |

The Versicolor palette retains its Dracula attribution; see [NOTICES.md](NOTICES.md).

Choose one in setup without repeating the language mapping:

```lua
require("argiope").setup({
  theme = { variant = "ocyaloides" },
})
vim.cmd.colorscheme("argiope")
```

Add a user theme by extending a generated definition. Definitions are deeply
merged, so only changed values need to be included:

```lua
require("argiope").setup({
  theme = {
    variant = "my-ocyaloides",
    definitions = {
      ["my-ocyaloides"] = {
        extends = "ocyaloides",
        name = "My Ocyaloides",
        base = { bg = "#101214" },
        languages = {
          javascript = {
            colors = { gray_warm = "#C68BAD" },
            roles = { keyword = "gray_warm" },
          },
        },
      },
    },
  },
})
```

Switch live with `:ArgiopeThemeVariant versicolor`, or call
`set_theme_variant("versicolor")`. `get_theme_variant()` returns the active
profile. Each variant is deterministic; there is no separate syntax mode.

## Server-side HTML rendering

When Neovim is available on the server, Argiope can render a JavaScript source
snippet to a compact `<pre><code>` block using the same Tree-sitter queries and
interpolation-normalization pass as the plugin:

```lua
local argiope = require("argiope.render")
local rendered = argiope.render([[const card = html`<article>${title}</article>`]])

-- Send rendered.html with the snippet and rendered.css once per page.
```

`html(source)` and `css()` are also available separately. The HTML uses a
single-letter family wrapper (`j`, `h`, `c`, `m`, or `e`) and compact semantic
tones (`t0` through `t12`); it contains no capture names or parser metadata.
The first twelve tones retain Argiope's palette ladder and the final tone is a
stable comment role. Generated and explicit palettes both use the same compact
`t*` tones, and the markup itself contains no colors.

Generate CSS for the active profile, or name a profile without switching the
editor theme:

```lua
local neon_css = argiope.css({ variant = "versicolor-neon" })
local light_css = argiope.css({ variant = "trifasciata" })
```

Each family defines `--a-t0` through `--a-t12`, so client CSS can retheme a
rendered snippet without regenerating HTML:

```css
.a .h { --a-t4: #c678dd; } /* change the HTML main tone */
```

Each code-card `<pre>` also includes a readable language class such as
`lang-javascript`, `lang-lua`, or `lang-json`. Its background is the `--a-bg`
variable, so page CSS can theme complete cards by syntax without touching the
generated markup:

```css
pre.a.lang-json { --a-bg: #1b1010; }
pre.a.lang-lua { --a-bg: #0d1028; }
```

The stylesheet and markup default to the active theme profile. Select a
Versicolor profile for multicolored host JavaScript:

```lua
argiope.html(source, { variant = "versicolor" })
```

Versicolor markup uses semantic `g0` through `g11` classes because its colors
cannot be recovered from the monochrome shade level alone. The renderer
preserves source whitespace exactly, including indentation and tabs; layout
remains the browser `pre` element's responsibility.

Other installed Tree-sitter languages can use Neovim's normal highlighting and
injection pipeline directly:

```lua
local html = require("argiope.render").html(source, { language = "html" })
local lua = require("argiope.render").html(source, { language = "lua" })
```

Their standard captures use the bundled editor-theme semantic colours in the
compact `g0` through `g11` classes. Query-driven child injections (for example,
CSS and JavaScript in an HTML snippet) are included when their parsers and
queries are installed. JavaScript is the one specialized path: it retains
Argiope's tagged-template families and interpolation normalization.

Argiope isolates the structural HTML parser from `<script>` and `<style>` child
injections. A normalized highlighting pass colors literal script and style
content without letting their language trees recurse through `${...}` gaps.

Unknown tagged templates receive neutral highlighting under the bundled theme;
ordinary untagged template strings keep normal JavaScript highlighting.

The bundled theme also defines readable highlights for Snacks Picker and
Explorer. In Versicolor themes, JavaScript values are warm beige, constants
are golden yellow, and string literals are a neutral gray.

## Comments

Neovim's built-in `gc` operator follows the registered template language:
HTML and Markdown use `<!-- -->`, CSS uses `/* */`, and embedded JavaScript
uses `//`.

For markup that should stay syntactically valid in any JavaScript template,
`toggle_interpolation_selection()` wraps selected text in an empty
interpolation:

```lua
vim.keymap.set("x", "<leader>zc", function()
  require("argiope").toggle_interpolation_selection(0)
end, {
  desc = "Toggle template interpolation comment",
})
```

Characterwise selections wrap the exact selected text and may occupy part of
one line or span multiple lines. Visual Line selections wrap each nonblank
line. For example, selecting `margin: 0;` produces
`${''/* margin: 0; */}`. Selecting exactly the inside or outside of
`${value}` produces `${''/* value */}` without nesting an interpolation.

## Indentation

Use Neovim's normal `=` operator:

```text
gg=G       reindent the whole buffer
=ip        reindent the current paragraph
```

Argiope:

- indents template content one `shiftwidth` from the tag line;
- delegates embedded HTML and CSS structure to nvim-treesitter's indent
  queries, then rebases the result onto the surrounding JavaScript;
- indents multiline substitution bodies one additional `shiftwidth`;
- aligns closing backticks with their tag line; and
- gives unregistered tags such as `txt` a flat template baseline while
  preserving the existing JavaScript indent expression outside tagged
  templates.

Without the nvim-treesitter indent engine, embedded content falls back to a
flat template baseline.

## Health

Run:

```vim
:checkhealth argiope
```

The check reports the Neovim version, parsers, highlight and injection queries,
and the embedded-language indent engine. Missing optional language support is
a warning; install only the languages you use.
