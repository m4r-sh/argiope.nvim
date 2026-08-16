local palette = require("argiope.palette")

local M = {}
local variant
local light_cursor_clause = "n-v-c-sm:block-ArgiopeLightCursor"

local function set(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(group, target)
  set(group, { link = target })
end

local function select_light_cursor(enabled)
  local clauses = {}
  for _, clause in ipairs(vim.split(vim.o.guicursor, ",", { plain = true })) do
    if clause ~= "" and clause ~= light_cursor_clause then
      table.insert(clauses, clause)
    end
  end
  if enabled then
    table.insert(clauses, light_cursor_clause)
  end
  vim.o.guicursor = table.concat(clauses, ",")
end

local editor_capture_links = {
  ["@variable"] = "Identifier",
  ["@variable.builtin"] = "Special",
  ["@variable.parameter"] = "Identifier",
  ["@variable.member"] = "Identifier",
  ["@constant"] = "Constant",
  ["@constant.builtin"] = "Special",
  ["@module"] = "Identifier",
  ["@string"] = "String",
  ["@string.escape"] = "SpecialChar",
  ["@character"] = "Character",
  ["@boolean"] = "Boolean",
  ["@number"] = "Number",
  ["@number.float"] = "Float",
  ["@type"] = "Type",
  ["@type.builtin"] = "Type",
  ["@attribute"] = "PreProc",
  ["@property"] = "Identifier",
  ["@function"] = "Function",
  ["@function.call"] = "Function",
  ["@function.method"] = "Function",
  ["@function.method.call"] = "Function",
  ["@constructor"] = "Type",
  ["@operator"] = "Operator",
  ["@keyword"] = "Keyword",
  ["@keyword.function"] = "Keyword",
  ["@keyword.operator"] = "Operator",
  ["@keyword.import"] = "Include",
  ["@keyword.conditional"] = "Conditional",
  ["@keyword.repeat"] = "Repeat",
  ["@keyword.return"] = "Keyword",
  ["@comment"] = "Comment",
  ["@punctuation.delimiter"] = "Delimiter",
  ["@punctuation.bracket"] = "Delimiter",
  ["@punctuation.special"] = "Special",
  ["@label"] = "Label",
  ["@tag"] = "Tag",
  ["@tag.attribute"] = "Identifier",
  ["@tag.delimiter"] = "Delimiter",
  ["@markup.heading"] = "Title",
  ["@markup.link"] = "Underlined",
  ["@markup.raw"] = "String",
  ["@markup.strong"] = "Bold",
  ["@markup.italic"] = "Italic",
}

local function apply_editor_theme()
  local c = palette.base

  local groups = {
    Normal = { fg = c.fg, bg = c.bg },
    NormalFloat = { fg = c.fg, bg = c.menu },
    FloatBorder = { fg = c.purple, bg = c.menu },
    ColorColumn = { bg = c.menu },
    CursorColumn = { bg = c.selection },
    CursorLine = { bg = c.selection },
    CursorLineNr = { fg = c.yellow, bold = true },
    LineNr = { fg = c.gutter_fg },
    SignColumn = { fg = c.gutter_fg, bg = c.bg },
    FoldColumn = { fg = c.comment, bg = c.bg },
    Folded = { fg = c.comment, bg = c.menu },
    EndOfBuffer = { fg = c.nontext },
    NonText = { fg = c.nontext },
    Whitespace = { fg = c.nontext },
    SpecialKey = { fg = c.nontext },
    Directory = { fg = c.cyan },
    ErrorMsg = { fg = c.bright_red, bold = true },
    WarningMsg = { fg = c.orange, bold = true },
    MoreMsg = { fg = c.green },
    ModeMsg = { fg = c.fg, bold = true },
    Question = { fg = c.green },
    Search = { fg = c.black, bg = c.orange },
    IncSearch = { fg = c.black, bg = c.bright_yellow },
    CurSearch = { fg = c.black, bg = c.bright_yellow, bold = true },
    MatchParen = { fg = c.bright_green, bold = true },
    Pmenu = { fg = c.fg, bg = c.menu },
    PmenuSel = { fg = c.bright_white, bg = c.visual, bold = true },
    PmenuSbar = { bg = c.menu },
    PmenuThumb = { bg = c.gutter_fg },
    StatusLine = { fg = c.fg, bg = c.visual },
    StatusLineNC = { fg = c.comment, bg = c.menu },
    TabLine = { fg = c.comment, bg = c.menu },
    TabLineFill = { bg = c.black },
    TabLineSel = { fg = c.fg, bg = c.selection, bold = true },
    Title = { fg = c.purple, bold = true },
    Visual = { bg = c.visual_selection or c.visual },
    WinSeparator = { fg = c.gutter_fg },
    Comment = { fg = c.comment, italic = true },
    Constant = { fg = c.purple },
    String = { fg = c.yellow },
    Character = { fg = c.yellow },
    Number = { fg = c.purple },
    Boolean = { fg = c.purple },
    Float = { fg = c.purple },
    Identifier = { fg = c.cyan },
    Function = { fg = c.green },
    Statement = { fg = c.pink },
    Conditional = { fg = c.pink },
    Repeat = { fg = c.pink },
    Label = { fg = c.cyan },
    Operator = { fg = c.pink },
    Keyword = { fg = c.pink },
    Exception = { fg = c.pink },
    PreProc = { fg = c.pink },
    Include = { fg = c.pink },
    Define = { fg = c.pink },
    Macro = { fg = c.pink },
    PreCondit = { fg = c.pink },
    Type = { fg = c.cyan },
    StorageClass = { fg = c.pink },
    Structure = { fg = c.cyan },
    Typedef = { fg = c.cyan },
    Special = { fg = c.orange },
    SpecialChar = { fg = c.orange },
    Tag = { fg = c.cyan },
    Delimiter = { fg = c.fg },
    SpecialComment = { fg = c.comment, italic = true },
    Debug = { fg = c.red },
    Underlined = { fg = c.cyan, underline = true },
    Ignore = { fg = c.comment },
    Error = { fg = c.bright_red },
    Todo = { fg = c.purple, bold = true },
    DiffAdd = { fg = c.green },
    DiffChange = { fg = c.orange },
    DiffDelete = { fg = c.red },
    DiffText = { fg = c.bright_yellow, bold = true },
    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.orange },
    DiagnosticInfo = { fg = c.cyan },
    DiagnosticHint = { fg = c.green },
    DiagnosticOk = { fg = c.bright_green },
    SnacksPickerFile = { fg = c.fg },
    SnacksPickerDirectory = { fg = c.cyan },
    SnacksPickerDir = { fg = c.white },
    SnacksPickerPathHidden = { fg = c.comment },
    SnacksPickerPathIgnored = { fg = c.gutter_fg },
    SnacksPickerGitStatusUntracked = { fg = c.orange },
    SnacksPickerGitStatusIgnored = { fg = c.gutter_fg },
    SnacksPickerTree = { fg = c.gutter_fg },
    SnacksPickerListCursorLine = { bg = c.selection },
  }

  if c.cursor then
    local cursor = { fg = c.bg, bg = c.cursor }
    groups.Cursor = cursor
    groups.lCursor = cursor
    groups.CursorIM = cursor
    groups.TermCursor = cursor
    groups.ArgiopeLightCursor = cursor
  end

  select_light_cursor(c.cursor ~= nil)

  for group, spec in pairs(groups) do
    set(group, spec)
  end

  for group, target in pairs(editor_capture_links) do
    link(group, target)
  end

  vim.g.terminal_color_0 = c.black
  vim.g.terminal_color_1 = c.red
  vim.g.terminal_color_2 = c.green
  vim.g.terminal_color_3 = c.yellow
  vim.g.terminal_color_4 = c.purple
  vim.g.terminal_color_5 = c.pink
  vim.g.terminal_color_6 = c.cyan
  vim.g.terminal_color_7 = c.white
  vim.g.terminal_color_8 = c.gutter_fg
  vim.g.terminal_color_9 = c.bright_red
  vim.g.terminal_color_10 = c.bright_green
  vim.g.terminal_color_11 = c.bright_yellow
  vim.g.terminal_color_12 = c.bright_blue
  vim.g.terminal_color_13 = c.bright_magenta
  vim.g.terminal_color_14 = c.bright_cyan
  vim.g.terminal_color_15 = c.bright_white
end

local language_groups = {
  javascript = {
    ["@none"] = "main",
    ["@variable"] = "main",
    ["@variable.builtin"] = "bright",
    ["@variable.parameter"] = "light",
    ["@variable.member"] = "soft",
    ["@constant"] = "bright",
    ["@constant.builtin"] = "light",
    ["@module"] = "muted",
    ["@module.builtin"] = "accent",
    ["@string"] = "muted",
    ["@string.escape"] = "bright",
    ["@string.regexp"] = "soft",
    ["@string.special"] = "accent",
    ["@character"] = "soft",
    ["@character.special"] = "bright",
    ["@boolean"] = "bright",
    ["@number"] = "accent",
    ["@number.float"] = "bright",
    ["@type"] = "light",
    ["@type.builtin"] = "bright",
    ["@attribute"] = "accent",
    ["@property"] = "soft",
    ["@function"] = "accent",
    ["@function.call"] = "bright",
    ["@function.builtin"] = "light",
    ["@function.method"] = "accent",
    ["@function.method.call"] = "bright",
    ["@constructor"] = "light",
    ["@operator"] = "soft",
    ["@keyword"] = "gray_warm",
    ["@keyword.conditional"] = "bright",
    ["@keyword.conditional.ternary"] = "accent",
    ["@keyword.coroutine"] = "accent",
    ["@keyword.directive"] = "soft",
    ["@keyword.exception"] = "light",
    ["@keyword.function"] = "soft",
    ["@keyword.import"] = "gray",
    ["@keyword.modifier"] = "muted",
    ["@keyword.operator"] = "accent",
    ["@keyword.repeat"] = "bright",
    ["@keyword.return"] = "light",
    ["@keyword.type"] = "main",
    ["@comment"] = "gray_dim",
    ["@comment.documentation"] = "gray",
    ["@punctuation.delimiter"] = "gray",
    ["@punctuation.bracket"] = "gray_dim",
    ["@punctuation.special"] = "gray_dim",
    ["@argiope.interpolation.delimiter"] = "gray_dim",
    ["@argiope.unknown.tag"] = "gray",
    ["@argiope.unknown.template"] = "gray",
    ["@argiope.unknown.delimiter"] = "gray_dim",
    ["@label"] = "main",
  },
  html = {
    ["@none"] = "light",
    ["@keyword"] = "muted",
    ["@tag"] = "main",
    ["@tag.delimiter"] = "darkest",
    ["@tag.attribute"] = "main",
    ["@operator"] = "accent",
    ["@string"] = "light",
    ["@string.special.url"] = "light",
    ["@constant"] = "accent",
    ["@character.special"] = "accent",
    ["@comment"] = "muted",
    ["@markup.heading"] = "accent",
    ["@markup.heading.1"] = "accent",
    ["@markup.heading.2"] = "accent",
    ["@markup.heading.3"] = "accent",
    ["@markup.heading.4"] = "accent",
    ["@markup.heading.5"] = "accent",
    ["@markup.heading.6"] = "accent",
    ["@markup.strong"] = "main",
    ["@markup.italic"] = "main",
    ["@markup.strikethrough"] = "muted",
    ["@markup.underline"] = "main",
    ["@markup.raw"] = "light",
    ["@markup.link.label"] = "main",
  },
  css = {
    ["@keyword"] = "main",
    ["@keyword.directive"] = "main",
    ["@keyword.import"] = "main",
    ["@keyword.operator"] = "main",
    ["@keyword.modifier"] = "accent",
    ["@comment"] = "muted",
    ["@tag"] = "main",
    ["@tag.attribute"] = "main",
    ["@type"] = "main",
    ["@constant"] = "accent",
    ["@property"] = "main",
    ["@function"] = "accent",
    ["@attribute"] = "accent",
    ["@module"] = "main",
    ["@variable"] = "main",
    ["@string"] = "muted",
    ["@value"] = "soft",
    ["@number"] = "accent",
    ["@number.float"] = "accent",
    ["@operator"] = "main",
    ["@character.special"] = "accent",
    ["@punctuation.delimiter"] = "gray_dim",
    ["@punctuation.bracket"] = "muted",
  },
  markdown = {
    ["@spell"] = "gray",
    ["@nospell"] = "gray",
    ["@markup.heading"] = "accent",
    ["@markup.heading.1"] = "accent",
    ["@markup.heading.2"] = "accent",
    ["@markup.heading.3"] = "main",
    ["@markup.heading.4"] = "main",
    ["@markup.heading.5"] = "muted",
    ["@markup.heading.6"] = "muted",
    ["@label"] = "main",
    ["@markup.raw"] = "muted",
    ["@markup.raw.block"] = "muted",
    ["@markup.link"] = "main",
    ["@markup.link.url"] = "main",
    ["@markup.link.label"] = "light",
    ["@markup.list"] = "main",
    ["@markup.list.text"] = "soft",
    ["@markup.list.checked"] = "accent",
    ["@markup.list.unchecked"] = "muted",
    ["@markup.quote"] = "muted",
    ["@markup.strong"] = "accent",
    ["@markup.italic"] = "main",
    ["@markup.strikethrough"] = "muted",
    ["@punctuation.special"] = "main",
    ["@punctuation.delimiter"] = "muted",
    ["@keyword.directive"] = "main",
    ["@string.escape"] = "accent",
    ["@character.special"] = "accent",
    ["@conceal"] = "darkest",
  },
}

language_groups.markdown_inline = language_groups.markdown
language_groups.argiope_javascript = language_groups.javascript

local styled_groups = {
  ["@comment"] = { italic = true },
  ["@markup.heading"] = { bold = true },
  ["@markup.heading.1"] = { bold = true },
  ["@markup.heading.2"] = { bold = true },
  ["@markup.heading.3"] = { bold = true },
  ["@markup.heading.4"] = { bold = true },
  ["@markup.heading.5"] = { bold = true },
  ["@markup.heading.6"] = { bold = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.underline"] = { underline = true },
  ["@markup.link"] = { underline = true },
  ["@markup.link.url"] = { underline = true },
  ["@markup.quote"] = { italic = true },
}

local function capture_shade(groups, group)
  local candidate = group
  while candidate do
    local shade = groups[candidate]
    if shade then
      return shade
    end
    candidate = candidate:match("^(.*)%.[^.]+$")
  end
  return "main"
end

local function interpreted_shade(groups, group)
  return capture_shade(groups, group)
end

local function capture_groups(language)
  local groups = language_groups[language]
  if not groups then
    if language == "argiope_html" then
      groups = language_groups.html
    elseif language == "argiope_javascript" then
      groups = language_groups.javascript
    elseif language == "markdown_inline" then
      groups = language_groups.markdown
    end
  end
  return groups or language_groups.javascript
end

local function is_comment(group)
  return group == "@comment" or group:sub(1, #"@comment.") == "@comment."
end

local function is_light_comment(group)
  return variant == "trifasciata"
    and (group == "@comment" or group:sub(1, #"@comment.") == "@comment.")
end

local function interpreted_color(colors, group, shade)
  if is_light_comment(group) then
    return palette.get("gray").gray_dim
  end
  return colors[shade]
end

local function apply_language(language, palette_name, include_query_captures)
  local colors = palette.get(palette_name)
  if not colors then
    error(("argiope: unknown palette %q for %s"):format(palette_name, language))
  end

  local groups = language_groups[language]
  local applied = {}
  for group, shade in pairs(groups) do
    local spec = vim.tbl_extend(
      "force",
      { fg = interpreted_color(colors, group, shade) },
      styled_groups[group] or {}
    )
    set(("%s.%s"):format(group, language), spec)
    applied[group] = true
  end

  if not include_query_captures then
    return
  end

  local ok, query = pcall(
    vim.treesitter.query.get,
    include_query_captures,
    "highlights"
  )
  if not ok or not query then
    return
  end

  for _, capture in ipairs(query.captures) do
    local group = "@" .. capture
    if capture:sub(1, 1) ~= "_" and not applied[group] then
      local shade = interpreted_shade(groups, group)
      local spec = vim.tbl_extend(
        "force",
        { fg = interpreted_color(colors, group, shade) },
        styled_groups[group] or {}
      )
      set(("%s.%s"):format(group, language), spec)
    end
  end
end

local versicolor_javascript_tones = {
  ["@variable"] = "beige",
  ["@variable.builtin"] = "orange",
  ["@variable.parameter"] = "beige",
  ["@variable.member"] = "beige",
  ["@constant"] = "golden_yellow",
  ["@constant.builtin"] = "golden_yellow",
  ["@string"] = "string_gray",
  ["@string.escape"] = "orange",
  ["@string.regexp"] = "string_gray",
  ["@string.special"] = "orange",
  ["@character"] = "string_gray",
  ["@character.special"] = "golden_yellow",
}

local versicolor_javascript_specs = {
  ["@argiope.interpolation.delimiter"] = { link = "Delimiter" },
  ["@argiope.unknown.delimiter"] = { tone = "nontext" },
  ["@argiope.unknown.tag"] = { tone = "comment" },
  ["@argiope.unknown.template"] = { tone = "comment" },
}

local function editor_capture_target(group)
  local candidate = group
  while candidate do
    local target = editor_capture_links[candidate]
    if target then
      return target
    end
    candidate = candidate:match("^(.*)%.[^.]+$")
  end
  return "Normal"
end

local function apply_versicolor_javascript()
  for group in pairs(language_groups.javascript) do
    local special = versicolor_javascript_specs[group]
    local tone = versicolor_javascript_tones[group] or special and special.tone
    local spec = tone and { fg = palette.base[tone] }
      or special and special.link and { link = special.link }
      or { link = editor_capture_target(group) }
    set(("%s.javascript"):format(group), spec)
  end
end

local function validate_variant(value)
  if not palette.profile(value) then
    error(
      ("argiope: unknown theme variant %q"):format(
        tostring(value)
      )
    )
  end
end

local function is_argiope_colorscheme()
  return vim.g.colors_name == "argiope"
    or type(vim.g.colors_name) == "string"
      and vim.g.colors_name:sub(1, 8) == "argiope-"
end

function M.apply(next_variant)
  if next_variant ~= nil then
    validate_variant(next_variant)
    variant = next_variant
  elseif variant == nil then
    variant = require("argiope.config").get().theme.variant
  end

  palette.select(variant)

  -- Set the target name before changing 'background'. Neovim may reload the
  -- active colorscheme when that option flips, and it must reload the new
  -- profile rather than the one we are leaving.
  vim.g.colors_name = "argiope-" .. variant
  vim.o.background = palette.background
  vim.opt.termguicolors = true
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "argiope-" .. variant
  apply_editor_theme()

  local configured = require("argiope.config").get_palettes(variant)
  if palette.profile().syntax == "versicolor" then
    apply_versicolor_javascript()
  else
    apply_language("javascript", configured.javascript or "gold")
  end
  apply_language(
    "argiope_javascript",
    configured.javascript_embedded or "gray",
    "argiope_javascript"
  )
  apply_language("html", configured.html or "blue")
  apply_language("css", configured.css or "green")
  apply_language("markdown", configured.markdown or "beige")
  apply_language("markdown_inline", configured.markdown or "beige")

  return variant
end

function M.get_variant()
  return variant or require("argiope.config").get().theme.variant
end

function M.set_variant(next_variant)
  validate_variant(next_variant)
  variant = next_variant

  if is_argiope_colorscheme() then
    M.apply()
  else
    palette.select(variant)
  end

  return variant
end

-- Shared by the HTML renderer. Keeping this lookup next to the colorscheme
-- prevents a server-side rendering from drifting when a capture is retuned.
function M.capture_style(language, capture)
  local groups = capture_groups(language)
  local group = "@" .. capture
  local style = styled_groups[group] or {}
  return {
    -- Tone names are stable rendering semantics. Profiles resolve them to
    -- palette shades in CSS, so switching themes never changes snippet HTML.
    tone = is_comment(group) and "comment" or interpreted_shade(groups, group),
    bold = style.bold == true,
    italic = style.italic == true,
    strikethrough = style.strikethrough == true,
    underline = style.underline == true,
  }
end

-- Resolve a stable renderer tone for one theme profile. Comments are the one
-- deliberately semantic tone beyond the twelve palette shades: Trifasciata renders
-- every language's comments through the neutral gray palette, while dark
-- profiles keep each language family's established comment shade.
function M.resolve_capture_tone(language, tone, profile_name)
  if tone ~= "comment" then
    return { shade = tone }
  end
  if profile_name == "trifasciata" then
    return { shade = "gray_dim", palette = "gray" }
  end
  return {
    shade = interpreted_shade(capture_groups(language), "@comment"),
  }
end

local editor_tones = {
  Normal = "fg",
  Identifier = "cyan",
  Special = "orange",
  Constant = "purple",
  String = "yellow",
  Character = "yellow",
  Boolean = "purple",
  Number = "purple",
  Float = "purple",
  Type = "cyan",
  PreProc = "pink",
  Function = "green",
  Operator = "pink",
  Keyword = "pink",
  Conditional = "pink",
  Repeat = "pink",
  Comment = "comment",
  Delimiter = "fg",
  Label = "cyan",
  Tag = "cyan",
  Title = "purple",
  Underlined = "cyan",
}

-- The bundled editor theme is the portable fallback for languages Argiope
-- does not specialize. It gives a Node/HTML/etc renderer the same semantic
-- colours Neovim would assign to its standard capture groups.
function M.editor_capture_style(capture)
  local group = "@" .. capture
  local style = styled_groups[group] or {}
  return {
    tone = editor_tones[editor_capture_target(group)] or "fg",
    bold = style.bold == true,
    italic = style.italic == true,
    strikethrough = style.strikethrough == true,
    underline = style.underline == true,
  }
end

function M.versicolor_javascript_style(capture)
  local group = "@" .. capture
  local candidate = group
  while candidate and not language_groups.javascript[candidate] do
    candidate = candidate:match("^(.*)%.[^.]+$")
  end
  if not candidate then
    return M.editor_capture_style(capture)
  end

  local special = versicolor_javascript_specs[candidate]
  local style = styled_groups[candidate] or {}
  local tone = versicolor_javascript_tones[candidate] or special and special.tone
  if tone then
    -- already resolved
  elseif special and special.link then
    tone = editor_tones[special.link] or "fg"
  else
    tone = editor_tones[editor_capture_target(candidate)] or "fg"
  end
  return {
    tone = tone,
    bold = style.bold == true,
    italic = style.italic == true,
    strikethrough = style.strikethrough == true,
    underline = style.underline == true,
  }
end

return M
