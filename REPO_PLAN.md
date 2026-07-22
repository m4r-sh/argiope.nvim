# argiope.nvim -- Repository Plan

## Goal

Build a Neovim 0.12+ plugin that provides first-class editing support
for tagged JavaScript template literals containing embedded languages.

Primary goals:

-   Excellent syntax highlighting
-   Intuitive indentation
-   Structural motions
-   Regression-test-driven development
-   Native Neovim package layout (no lazy.nvim required)

LSP support is explicitly out of scope.

------------------------------------------------------------------------

# High-level Architecture

The JavaScript parser remains the host language.

Tagged template literals inject custom embedded Tree-sitter languages:

``` text
javascript
├── js_template_css
│   └── javascript interpolation
├── js_template_html
│   └── javascript interpolation
├── js_template_markdown
│   └── javascript interpolation
└── js_template_svg
```

Each embedded language understands `${...}` as a structural
interpolation node and injects JavaScript back into the interpolation
expression.

The JavaScript grammar should remain upstream whenever possible.

## Nested templates

Nested tagged templates are a first-class design goal.

Example:

``` js
let document = md`
# ${myTitle}

${list.map(item => md`
  - [ ] ${item.name}
`)}

`
```

The model layer, grammar structure, motions, highlighting, and
indentation should all correctly support arbitrary nesting of embedded
template languages.

------------------------------------------------------------------------

# Repository Layout

``` text
js-template-languages.nvim/
├── plugin/
├── ftplugin/
├── lua/
│   └── js_template_languages/
│       ├── init.lua
│       ├── config.lua
│       ├── registry.lua
│       ├── model.lua
│       ├── motions.lua
│       ├── indent.lua
│       ├── highlight.lua
│       └── theme.lua
├── queries/
│   ├── javascript/
│   ├── js_template_css/
│   ├── js_template_html/
│   ├── js_template_markdown/
│   └── js_template_svg/
├── grammars/
│   ├── css/
│   ├── html/
│   ├── markdown/
│   └── svg/
├── parser/
├── tests/
│   ├── grammar/
│   ├── injections/
│   ├── highlight/
│   ├── indent/
│   ├── model/
│   └── fixtures/
└── README.md
```

------------------------------------------------------------------------

# Shared Interpolation Contract

Every embedded grammar should expose:

``` text
interpolation
    "${"
    expression
    "}"
```

This enables shared JavaScript injections, shared motions, shared
indentation routing, and a common structural model.

------------------------------------------------------------------------

# Lua Modules

-   **registry.lua** -- maps tag names to embedded languages.
-   **model.lua** -- structural API for templates, interpolations,
    ownership, and injected trees.
-   **indent.lua** -- indentation engine built on the model layer.
-   **motions.lua** -- structural navigation.
-   **highlight.lua** -- runtime highlight setup.
-   **theme.lua** -- palette mapping.

------------------------------------------------------------------------

# Theme Configuration

``` lua
require("js_template_languages").setup({
    palettes = {
        css = "green",
        html = "blue",
        markdown = "beige",
        svg = "cyan",
    },
})
```

JavaScript retains the user's normal colorscheme (for example Dracula).

Embedded languages use monochrome palettes selected by name. Tree-sitter
queries emit semantic captures only; the theme layer maps those captures
to palette-specific highlight groups.

------------------------------------------------------------------------

# Testing Strategy

Separate suites by responsibility:

-   grammar/
-   injections/
-   highlight/
-   indent/
-   model/

## Indentation

Indentation should be heavily test-driven.

Two complementary test styles:

1.  **Golden formatting fixtures**

Each case contains:

-   `example.input.js`
-   `example.expected.js`

Tests load the input into a real Neovim instance, invoke the plugin's
indentation (`=`), and compare the resulting buffer against the expected
file.

As bugs are discovered, add fixtures before changing implementation.

2.  **Insertion-behavior tests**

Exercise interactive editing behavior (Enter, `o`, `O`, etc.) so the
typing experience remains stable in addition to whole-buffer formatting.

Use Plenary's test runner so tests execute inside an actual Neovim
instance with a minimal init.

------------------------------------------------------------------------

# Development Plan

## Phase 1

Focus on building the development environment and proving the
architecture:

-   Scaffold the repository.
-   Consume the plugin from a real personal Neovim configuration.
-   Build the testing harness.
-   Implement the indentation engine first.
-   Establish regression fixtures and insertion tests.

This phase validates the plugin architecture and development workflow
before investing heavily in custom grammars.

## Phase 2

Incrementally add embedded language support:

-   CSS
-   HTML
-   Markdown
-   SVG

Extend upstream grammars where appropriate to support `${}` in
language-specific positions.

Add highlighting, motions, grammar tests, and indentation support one
language at a time.

Advanced highlighting and embedded grammar work should be designed for
from the beginning, but they do not need to be implemented all at once.

------------------------------------------------------------------------

# Grammar Philosophy

These grammars are not intended to be faithful forks of their upstream counterparts. Their primary goal is to produce intuitive editing behavior inside JavaScript template literals. Where upstream language syntax and template interpolation conflict, the template-aware grammar should favor editability, stable parsing, highlighting, and indentation over strict language conformance

# Non-goals

-   TypeScript
-   Embedded LSPs
-   Embedded completion
-   Formatter integration
-   Plugin-manager-specific setup

The focus is excellent editing support for JavaScript tagged template
literals.
