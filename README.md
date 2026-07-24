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
- bare tag aliases such as `md` and member-expression aliases such as
  `ui.md`;
- an optional dark colorscheme with a distinct monochrome palette for each
  language; and
- `:checkhealth argiope` diagnostics.

Argiope does not add pairing, surround, or `Enter` mappings. Those choices stay
in the user's Neovim configuration.

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
  palettes = {
    css = "green",
    html = "cyan",
    javascript = "gold2",
    javascript_embedded = "gray",
    markdown = "violet",
  },
})
```

`tags` maps JavaScript tag spellings to `html`, `css`, `javascript`, or
`markdown`. Exact member-expression tags such as the default `raw.js` entry
are supported. Bare names also match the final property of a member
expression, so adding `prose = "markdown"` enables both `prose\`...\`` and
`ui.prose\`...\``.

Set `enabled = false` to disable the plugin globally, or disable indentation
and highlighting independently. `shiftwidth = 0` uses the buffer's existing
`shiftwidth` (falling back to `tabstop`).

Available palette names are `gold` (also available as `beige`), `gold2`,
`gray`, `blue`, `indigo`, `violet`, `blush`, `pink`, `green`, and `cyan`.

## Colorscheme

Argiope's editing support works with the user's existing colorscheme. To use
the bundled theme:

```lua
vim.cmd.colorscheme("argiope")
```

The editor palette is adapted from the MIT-licensed Dracula palette, with a
darker background and additional UI colors. Embedded HTML, CSS, Markdown, and
JavaScript use separately configurable monochrome palettes. Embedded
JavaScript is gray by default, independently of top-level JavaScript. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for attribution.

The default `monochrome` mode also gives JavaScript its configured monochrome
palette. Toggle to `hybrid` mode to keep the embedded languages monochrome
while restoring multicolored, near-default Dracula JavaScript syntax:

```lua
vim.keymap.set("n", "<leader>zt", require("argiope").toggle_theme, {
  desc = "Toggle Argiope JavaScript colors",
})
```

The same behavior is available through `:ArgiopeThemeToggle`. Use
`get_theme_mode()` to read the current mode or
`set_theme_mode("monochrome")` / `set_theme_mode("hybrid")` to select one
directly. The selected mode persists when the Argiope colorscheme is reapplied.

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
`toggle_interpolation_comment()` wraps selected lines in an empty
interpolation:

```lua
vim.keymap.set("x", "<leader>zc", function()
  require("argiope").toggle_interpolation_comment(
    0,
    vim.fn.line("v"),
    vim.fn.line(".")
  )
end, {
  desc = "Toggle template interpolation comment",
})
```

For example, `margin: 0;` becomes `${''/* margin: 0; */}`. Calling the action
on the wrapped line restores the original text.

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
- preserves the existing JavaScript indent expression outside registered
  templates.

Without the nvim-treesitter indent engine, embedded content falls back to a
flat template baseline.

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

The HSL palette source lives in `palette/theme.js`; generate the committed Lua
module with:

```sh
bun run palette
```

See [CHANGELOG.md](CHANGELOG.md) for release notes. Argiope is available under
the [MIT License](LICENSE).

[nvim-treesitter]: https://github.com/neovim-treesitter/nvim-treesitter
[parser-registry]: https://github.com/neovim-treesitter/treesitter-parser-registry
