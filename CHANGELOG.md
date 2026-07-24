# Changelog

## Unreleased

- Add a hybrid theme mode and `:ArgiopeThemeToggle`, keeping embedded
  languages monochrome while restoring multicolored Dracula JavaScript syntax.
- Isolate HTML child injections to prevent recursive parsing through
  substitutions in `<script>` and `<style>` elements.
- Recognize `raw.js` as embedded JavaScript with an independently configurable
  gray palette.

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
