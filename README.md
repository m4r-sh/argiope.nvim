# argiope.nvim

Argiope gives JavaScript tagged template literals first-class embedded-language
highlighting and indentation in Neovim.

```javascript
const card = html`
  <article class="${cardClass}">
    <h2>${title}</h2>
  </article>
`

const styles = css`
  article {
    color: ${textColor};
  }
`

const notes = md`
  ## ${title}

  - Embedded Markdown stays readable.
`

const script = raw.js`
  const theme = localStorage.theme
`
```

It provides:

- Tree-sitter HTML, CSS, Markdown, and JavaScript injections with substitutions
  kept in the host tree;
- embedded-language-aware indentation for template content, nested structures,
  substitutions, and closing backticks;
- HTML-aware `J` behavior that removes whitespace at element boundaries;
- bare tag aliases such as `md` and member-expression aliases such as
  `ui.md`;
- an optional multi-profile colorscheme with a distinct hue family for each
  language; and
- `:checkhealth argiope` diagnostics.

Argiope does not add pairing, surround, or `Enter` mappings. It adds a
buffer-local `J` mapping only when `J` is otherwise unmapped; this behavior can
be disabled independently.

## Requirements

- Neovim 0.12+
- Git when installing with `vim.pack`
- [neovim-treesitter/nvim-treesitter][nvim-treesitter] and its
  [parser registry][parser-registry]
- the `javascript`, `html`, `css`, `markdown`, and `markdown_inline`
  Tree-sitter parsers and queries
- the `ecma`, `jsx`, and `html_tags` inherited query packages used by the
  current distributed nvim-treesitter registry

Installing parsers through nvim-treesitter also requires `curl`,
`tree-sitter` CLI 0.26.1+, and a C compiler. Argiope itself has no install-time
build step; its generated Lua palette is committed to the repository.

Argiope currently attaches only to the `javascript` filetype. TypeScript and
SVG are not part of the first release.

## Install with `vim.pack`

Add the parser registry before nvim-treesitter, then Argiope:

```lua
vim.pack.add({
  {
    src = "https://github.com/neovim-treesitter/treesitter-parser-registry",
  },
  {
    src = "https://github.com/neovim-treesitter/nvim-treesitter",
  },
  {
    src = "https://github.com/m4r-sh/argiope.nvim",
    version = vim.version.range("0.1"),
  },
}, {
  load = true,
})

require("argiope").setup()
```

Install the required parsers once:

```vim
:lua require("nvim-treesitter").install({ "javascript", "html", "css", "markdown", "markdown_inline", "ecma", "jsx", "html_tags" }):wait(300000)
```

When nvim-treesitter changes, update its installed parsers and queries with
`:TSUpdate`.

The `version` constraint follows compatible `v0.1.x` tags. Remove it if you
prefer to follow the repository's default branch.

## Configuration

Calling `setup()` is optional when using the defaults. The complete default
configuration is:

```lua
require("argiope").setup({
  enabled = true,
  filetypes = {
    javascript = true,
  },
  tags = {
    css = "css",
    html = "html",
    md = "markdown",
    ["raw.js"] = "javascript",
  },
  indent = {
    enabled = true,
    shiftwidth = 2,
    expandtab = true,
  },
  highlight = {
    enabled = true,
  },
  join = {
    enabled = true,
  },
  theme = {
    variant = "classic",
    palettes = {},
  },
  palettes = {},
})
```

`tags` maps JavaScript tag spellings to `html`, `css`, `javascript`, or
`markdown`. Exact member-expression tags such as the default `raw.js` entry
are supported. Bare names also match the final property of a member
expression, so adding `prose = "markdown"` enables both `prose\`...\`` and
`ui.prose\`...\``.

Set `enabled = false` to disable the plugin globally, or disable indentation,
highlighting, and joining independently. `shiftwidth = 0` uses the buffer's
existing `shiftwidth` (falling back to `tabstop`).

Available palette names are `gold` (also available as `beige`), `gold2`,
`gray`, `blue`, `indigo`, `violet`, `blush`, `ember`, `slate`, `pink`,
`green`, and `cyan`.

## Colorscheme

Argiope's editing support works with the user's existing colorscheme. To use
the bundled theme:

```lua
vim.cmd.colorscheme("argiope")
```

Embedded HTML, CSS, Markdown, and JavaScript use separately configurable hue
families. Each profile supplies its own language defaults, and three additive
profiles are generated in OKLCH with
[cusphanger](https://github.com/meodai/cusphanger):

- `classic` preserves the original palette exactly and uses gold JavaScript;
- `contrast` uses the same language families with a wider lightness range and
  stronger chroma;
- `quiet` uses gray JavaScript plus lower-contrast, less-saturated colored
  embedded languages; and
- `day` uses a compact neutral JavaScript ramp plus vivid deep-blue HTML and
  green CSS on a light background.

The built-in assignments are:

| Profile | JavaScript | Embedded JavaScript | HTML | CSS | Markdown |
| --- | --- | --- | --- | --- | --- |
| `classic`, `contrast` | `gold2` | `gray` | `cyan` | `green` | `blush` |
| `quiet` | `gray` | `gray` | `cyan` | `green` | `blush` |
| `day` | `gray` | `gray` | `blue` | `green` | `blush` |

The unchanged `classic` profile retains its Dracula attribution; see
[NOTICES.md](NOTICES.md). The three generated profiles are separate palettes.

Choose one in setup without repeating the language mapping:

```lua
require("argiope").setup({
  theme = { variant = "quiet" },
})
vim.cmd.colorscheme("argiope")
```

Top-level `palettes` entries override a language in every profile. To keep
different assignments when switching profiles, put them under
`theme.palettes` instead:

```lua
require("argiope").setup({
  palettes = { markdown = "violet" }, -- optional global override
  theme = {
    variant = "quiet",
    palettes = {
      quiet = { html = "cyan", css = "slate" },
      day = { html = "blue", css = "green" },
    },
  },
})
```

Switch live with `:ArgiopeThemeVariant day`, or call
`set_theme_variant("day")`. `get_theme_variant()` returns the active profile.

The default `monochrome` mode also gives JavaScript its configured hue family.
Toggle to `hybrid` mode to keep the embedded languages monochrome while using
the active profile's multicolored semantic JavaScript syntax:

```lua
vim.keymap.set("n", "<leader>zt", require("argiope").toggle_theme, {
  desc = "Toggle Argiope JavaScript colors",
})
```

The same behavior is available through `:ArgiopeThemeToggle`. Use
`get_theme_mode()` to read the current mode or
`set_theme_mode("monochrome")` / `set_theme_mode("hybrid")` to select one
directly. The selected mode persists when the Argiope colorscheme is reapplied.

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
stable comment role. HTML does not depend on the active theme profile.

Generate CSS for the active profile, or name a profile without switching the
editor theme:

```lua
local night_css = argiope.css({ variant = "contrast" })
local day_css = argiope.css({ variant = "day" })
```

Each family defines `--a-h` and `--a-gh`, its chromatic and neutral hue
variables, so client CSS can also retheme a family without regenerating HTML:

```css
.a .h { --a-h: 300; --a-gh: 300; } /* make embedded HTML violet */
```

Each code-card `<pre>` also includes a readable language class such as
`lang-javascript`, `lang-lua`, or `lang-json`. Its background is the `--a-bg`
variable, so page CSS can theme complete cards by syntax without touching the
generated markup:

```css
pre.a.lang-json { --a-bg: #1b1010; }
pre.a.lang-lua { --a-bg: #0d1028; }
```

The stylesheet defaults to the active theme profile. Set `mode = "hybrid"`
for the same host-JavaScript colors as `:ArgiopeThemeToggle`:

```lua
argiope.html(source, { mode = "hybrid" })
```

Hybrid markup uses semantic `g0` through `g11` classes because its colors
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
Explorer. In hybrid mode, JavaScript values are warm beige, constants are
golden yellow, and string literals are a neutral gray.

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

## Joining HTML

Inside a registered HTML template, normal or Visual mode `J` removes
indentation without adding whitespace between an opening tag and its content
or between content and a closing tag:

```javascript
const label = html`
  <div class=${BTN.LABEL}>${text}</div>
`
```

Joining ordinary prose still inserts a space, and `J` keeps its native behavior
outside HTML templates. Argiope installs this buffer-local mapping only when no
other `J` mapping is active. Set `join.enabled = false` to disable it.

## Health

Run:

```vim
:checkhealth argiope
```

The check reports the Neovim version, parsers, highlight and injection queries,
and the embedded-language indent engine.

## Development

Development uses an isolated dependency and XDG tree under the ignored
`.deps/` directory. It does not read or modify the normal Neovim profile.

Requirements are Bun 1.3.14, Git, `tree-sitter` CLI 0.26.1+, a C compiler, and
Neovim 0.12+.

```sh
bun run deps
bun run test
```

The full suite includes a clean-room smoke test that snapshots the working
tree into a temporary Git repository and installs it through real
`vim.pack.add()`. The deterministic local suite uses a pinned query snapshot;
CI also runs every behavior test against the current distributed
nvim-treesitter registry.

Open the highlight fixture in the isolated manual harness with:

```sh
bun run dev
bun run dev -- path/to/file.js
```

Hue-family definitions live in `palette/families.js`; profile parameters live
in `palette/profiles.js`; and `palette/theme.js` composes both through
cusphanger. Generate the committed Lua module with:

```sh
bun run palette
```

See [CHANGELOG.md](CHANGELOG.md) for release notes. Argiope is available under
the [MIT License](LICENSE).

[nvim-treesitter]: https://github.com/neovim-treesitter/nvim-treesitter
[parser-registry]: https://github.com/neovim-treesitter/treesitter-parser-registry
