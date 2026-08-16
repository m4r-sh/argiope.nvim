# Changelog

## Unreleased

- Give rendered HTML compact semantic tone classes and allow HTML/CSS
  generation for a named profile without changing the editor theme.
- Add six portable, deterministic theme profiles: Aurantia, Versicolor,
  Aurantia Neon, Versicolor Neon, Ocyaloides, and Trifasciata.
- Preserve CSS selector and declaration highlighting after interpolated class
  names followed by pseudo-classes such as `.${BTN}:hover`.
- Join opening tags, content, and closing tags with `J` without introducing
  whitespace inside registered HTML templates.
- Make native `gc` comments follow the registered tagged-template language
  and add exact-range, reversible empty-interpolation comments.
- Apply generic template indentation to unregistered tags such as `txt`.
- Give Versicolor JavaScript warm values, golden constants, and neutral strings.
- Brighten violet Markdown prose and add readable Snacks Explorer
  highlights.
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
