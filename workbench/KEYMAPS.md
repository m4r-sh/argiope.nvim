# Argiope Workbench Keymaps

`<leader>` is `<Space>`.

## Daily essentials

| Keys | Action |
| --- | --- |
| `<Space>w` | Save the current buffer |
| `<Space>q` | Quit the current window, prompting for unsaved changes |
| `[b` / `]b` | Previous / next buffer |
| `<Space>bd` | Delete the current buffer |
| `<Esc>` | Clear search highlighting |

## Search with fff

| Keys | Action |
| --- | --- |
| `<Space>ff` | Find files in the current project |
| `<Space>fg` | Search file contents |
| `<Space>fw` | Search the word under the cursor or visual selection |
| `<Space>fz` | Search file contents in fuzzy/plain mode |

Inside an fff picker:

| Keys | Action |
| --- | --- |
| `<CR>` | Open selection |
| `<Esc>` | Close picker |
| `<C-n>` / `<C-p>` | Move down / up |
| `<C-s>` | Open in a horizontal split |
| `<C-v>` | Open in a vertical split |
| `<C-t>` | Open in a tab |
| `<C-q>` | Send results to the quickfix list |
| `<S-Tab>` | Cycle grep modes |

## Files with oil.nvim

| Keys | Action |
| --- | --- |
| `-` | Open the current file's parent directory |
| `<Space>e` | Open Oil |
| `<CR>` | Open the entry under the cursor |
| `-` in Oil | Go to the parent directory |
| `:write` | Apply filesystem edits |
| `g?` in Oil | Show Oil's complete keymap help |

Oil buffers are editable directories: rename, create, move, or delete entries
by editing lines, then use `:write` to apply the changes.

## Surrounds

| Keys | Example |
| --- | --- |
| `ys{motion}{char}` | `ysiw)` wraps a word as `(word)` |
| `ys$"` | Wrap to end of line in quotes |
| `ds{char}` | `ds]` removes surrounding brackets |
| `cs{old}{new}` | `cs'"` changes single quotes to double quotes |
| `dst` | Remove the surrounding HTML tag |
| `csth1<CR>` | Change the surrounding tag to `<h1>` |
| `S{char}` in visual mode | Surround the selection |
| `` vi` `` / `` va` `` | Select inside / around a JavaScript template literal |
| `` di` `` / `` da` `` | Delete inside / around a JavaScript template literal |
| ``ysi`"`` | Surround a template literal's contents with double quotes |
| `` ds` `` / ``cs`"`` | Delete backticks / change backticks to double quotes |

Opening delimiters such as `(` add spaces; closing delimiters such as `)` do
not. The backtick text objects and surround targets are Tree-sitter-aware, so
they work across lines and select the nearest enclosing template literal.

## Argiope theme development

| Keys | Action |
| --- | --- |
| `<Space>pe` | Open the HSL palette source |
| `<Space>pr` | Regenerate and reload the palette |
| `<Space>hi` | Inspect Tree-sitter captures under the cursor |
| `<Space>ht` | Open the Tree-sitter syntax tree |

## Plugin maintenance

- `:lua vim.pack.update()` reviews available plugin updates.
- `:FFFHealth` checks fff and its native binary.
- `:checkhealth argiope` checks Argiope and its parsers.

No dedicated Git UI is installed yet. fff includes Git-aware file status and
ranking; choose a broader Git workflow after using the workbench for a while.
