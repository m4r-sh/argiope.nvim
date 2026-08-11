# Changelog

## Unreleased

- Add cusphanger-generated high-contrast, quiet, and day theme profiles while
  preserving the original palette and language-to-hue family configuration.
- Preserve CSS selector and declaration highlighting after interpolated class
  names followed by pseudo-classes such as `.${BTN}:hover`.
- Join opening tags, content, and closing tags with `J` without introducing
  whitespace inside registered HTML templates.
- Make native `gc` comments follow the registered tagged-template language
  and add exact-range, reversible empty-interpolation comments.
- Apply generic template indentation to unregistered tags such as `txt`.
- Improve hybrid JavaScript colors for values, constants, and string literals.
- Brighten violet Markdown prose and add readable Snacks Explorer
  highlights.
- Add a hybrid theme mode and `:ArgiopeThemeToggle`, keeping embedded
  languages monochrome while restoring multicolored JavaScript syntax.
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
