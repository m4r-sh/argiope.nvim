# Changelog

## 0.1.0 - 2026-07-23

Initial public release.

- Highlight HTML, CSS, and Markdown inside registered JavaScript tagged
  templates while keeping substitutions in the JavaScript tree.
- Preserve HTML attribute highlighting across consecutive unquoted JavaScript
  substitutions.
- Indent template content, nested embedded structures, substitutions, and
  closing backticks.
- Resolve bare tags and the final property of member-expression tags.
- Provide configurable language palettes, an optional Argiope colorscheme,
  and `:checkhealth argiope`.
- Support native installation through Neovim's `vim.pack`.
