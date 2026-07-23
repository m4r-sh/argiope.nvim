# argiope.nvim

Argiope is a Neovim 0.12+ plugin for editing JavaScript tagged template
literals. The current Phase 1 baseline provides:

- a Tree-sitter-backed structural model and two-space indentation;
- basic HTML, CSS, and Markdown injections;
- monochrome embedded-language palettes over a modified Dracula-style
  JavaScript colorscheme; and
- a pinned, isolated development and regression-test environment.

Argiope does not insert matching delimiters or map `Enter`. Pairing and
surround behavior remain under the user's own Neovim configuration.

## Requirements

Development and tests require Bun, Git, the `tree-sitter` CLI, a C compiler,
and Neovim 0.12+. The bootstrap script installs pinned test dependencies
beneath the ignored `.deps/` directory. It does not touch the normal Neovim
configuration, package directory, cache, or state.

For a regular installation, `nvim-treesitter` and the HTML, CSS, Markdown,
Markdown-inline, and JavaScript parsers must be on `runtimepath`.
`nvim-treesitter` supplies the standard highlight/indent queries and the
language-aware indent engine. The isolated development environment supplies
all of these automatically.

## Isolated development

The recommended launcher gives Neovim direct control of the terminal while
keeping all configuration and state isolated:

```sh
./dev.sh
```

With no arguments it opens the `zilk-ui` integration fixture. Pass any other
file to use it as the playground:

```sh
./dev.sh tests/fixtures/indent/html-nested.input.js
```

The script chooses an executable named `nvim12` before trying `nvim`, so the
system `nvim` alias is not used. An exact binary can still be selected:

```sh
NVIM_BIN=/absolute/path/to/nvim12 ./dev.sh
```

The development init loads the plugin, pinned parsers and queries, and
`:colorscheme argiope` inside project-local XDG directories. On macOS it also
enables `unnamedplus`, so normal yank, delete, and put operations use the
system clipboard.

### Palette iteration

Every editor and language palette is authored as HSL values in
`palette/theme.js`. `bun run palette` uses `Bun.color` to write the complete
hexadecimal Lua table consumed by Neovim. Do not edit
`lua/argiope/generated/palette.lua` directly.

All HSL inputs are integers. Every palette family shares one expressive
twelve-shade contract, so any palette can be assigned to JavaScript, HTML,
CSS, or Markdown without missing a shade. Individual families can override
the shared curve for hand-tuned colors.

For a side-by-side visual loop, start the default development session:

```sh
./dev.sh
```

Press `<Space>pe` to open the HSL source in a vertical split. After changing a
value, press `<Space>pr`; the dev-only mapping saves the source, regenerates
the Lua module, and reapplies the colorscheme without restarting Neovim.
The equivalent commands are `:ArgiopePaletteEdit` and
`:ArgiopePaletteReload`.

To identify the capture controlling a color, place the cursor on the token and
press `<Space>hi` (or run `:Inspect`). Press `<Space>ht` (or run
`:InspectTree`) to inspect the complete Tree-sitter syntax tree.

## Daily workbench

The persistent daily-use profile is separate from the reproducible development
harness:

```sh
./workbench.sh
./workbench.sh path/to/project
```

It loads local Argiope plus fff.nvim, oil.nvim, nvim-surround, and
nvim-treesitter-textobjects through Neovim 0.12's built-in `vim.pack`. Plugin
versions are recorded in `workbench/nvim-pack-lock.json`. Plugin data, undo
history, ShaDa, swap, cache, and other runtime state persist under the ignored
`.workbench/` directory. Unlike `dev.sh`, this launcher does not disable swap
or ShaDa and only bootstraps parsers when they are missing.

The profile is intentionally small. Personal options live in
`dev/settings.lua`, mappings in `dev/keymaps.lua`, and external plugin setup in
`dev/plugins.lua`. Relative line numbers and the macOS system clipboard are
enabled. See `workbench/KEYMAPS.md` for the short keymap reference.

## Configuration

```lua
require("argiope").setup({
  tags = {
    css = "css",
    html = "html",
    md = "markdown",
    svg = "svg",
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
    html = "blue",
    javascript = "gold",
    markdown = "cyan",
    svg = "cyan",
  },
})

vim.cmd.colorscheme("argiope")
```

Registered tag names also work as the final property of a member expression:
`ui.md\`...\`` resolves through the same `md = "markdown"` entry as
`md\`...\``. This applies to custom aliases in `tags` as well. Templates with
an unregistered tag, such as `txt\`...\``, use neutral gray highlighting;
ordinary untagged template strings retain the JavaScript string palette.

The base editor uses the modified Dracula palette. JavaScript—including code
inside `${...}`—defaults to varied yellow-gold shades with readable gray
punctuation and comments; `${` and `}` use a light gray. HTML defaults to blue,
CSS to green, and Markdown currently defaults to cyan. Available monochrome
palette names are `gold` (also aliased as `beige`), `gold2`, `gray`, `blue`,
`indigo`, `violet`, `blush`, `pink`, `green`, and `cyan`. `gold2` spans
20°–80° while keeping its most frequently used shades centered in the
familiar golden window.

Markdown template highlighting removes the template body's common JavaScript
indentation before its semantic pass. A `md` template nested inside a function
therefore keeps headings, prose, emphasis, links, and lists distinct instead of
being misread as one Markdown indented code block. Interpolation ranges remain
owned and colored by JavaScript.

Run `:checkhealth argiope` to verify the Neovim version, all required parsers
and queries, and the nvim-treesitter indent engine.

## Indentation

The JavaScript parser identifies registered tagged templates, interpolation
boundaries, nested templates, and which template owns a position. Complete
HTML and CSS template content is routed through nvim-treesitter's upstream
indent queries, then rebased onto the surrounding JavaScript indentation.
This means nested HTML elements and declarations inside CSS blocks receive
their language-native depth.

Use Neovim's normal `=` operator to apply it:

```text
gg=G       reindent the whole buffer
=ip        reindent the current paragraph
```

The indentation strategy:

- indents template content one `shiftwidth` from the tag's line;
- adds embedded HTML/CSS structural depth within that content baseline;
- aligns a closing backtick with the tag's line;
- indents multiline interpolation bodies one additional `shiftwidth`; and
- delegates ordinary JavaScript to Neovim's existing JavaScript indent script.

Live indentation while entering incomplete tags or blocks remains on the
generic template baseline for now; special insert-mode/`Enter` behavior is a
separate follow-up.

The current basic language injections use upstream parsers and query files.
Custom interpolation-aware embedded grammars remain a later phase.

## Tests

Run the complete isolated suite:

```sh
bun run test
```

The runner also prefers `nvim12`; set `NVIM_BIN` when a specific executable is
required. Narrow suites are available as:

```sh
bun run test:native
bun run test:indent
bun run test:integration
bun run test:model
bun run test:highlight
```

Golden indentation cases live in `tests/fixtures/indent` as matching
`*.input.js` and `*.expected.js` files. The highlight fixture at
`tests/fixtures/highlight/embedded.js` is both an automated regression input
and a convenient interactive playground. The larger `zilk-ui` case lives at
`tests/fixtures/integration/zilk-ui.js`.

See `REPO_PLAN.md` for the architecture and longer-term roadmap.
