local palette = require("argiope.palette")

local M = {}
local mode = "monochrome"

local supported_modes = {
  hybrid = true,
  monochrome = true,
}

local function set(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(group, target)
  set(group, { link = target })
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
    Visual = { bg = c.visual },
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
  }

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

local function apply_language(language, palette_name)
  local colors = palette.get(palette_name)
  if not colors then
    error(("argiope: unknown palette %q for %s"):format(palette_name, language))
  end

  for group, shade in pairs(language_groups[language]) do
    local spec = vim.tbl_extend("force", { fg = colors[shade] }, styled_groups[group] or {})
    set(("%s.%s"):format(group, language), spec)
  end
end

local hybrid_javascript_groups = {
  ["@argiope.interpolation.delimiter"] = { link = "Delimiter" },
  ["@argiope.unknown.delimiter"] = { fg = palette.base.nontext },
  ["@argiope.unknown.tag"] = { fg = palette.base.comment },
  ["@argiope.unknown.template"] = { fg = palette.base.comment },
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

local function apply_hybrid_javascript()
  for group in pairs(language_groups.javascript) do
    local spec = hybrid_javascript_groups[group]
      or { link = editor_capture_target(group) }
    set(("%s.javascript"):format(group), spec)
  end
end

local function validate_mode(value)
  if not supported_modes[value] then
    error(
      ("argiope: theme mode must be 'monochrome' or 'hybrid' (got %q)"):format(
        tostring(value)
      )
    )
  end
end

function M.apply(next_mode)
  if next_mode ~= nil then
    validate_mode(next_mode)
    mode = next_mode
  end

  vim.o.background = "dark"
  vim.opt.termguicolors = true
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "argiope"
  apply_editor_theme()

  local configured = require("argiope.config").get().palettes
  if mode == "hybrid" then
    apply_hybrid_javascript()
  else
    apply_language("javascript", configured.javascript or "gold")
  end
  apply_language("html", configured.html or "blue")
  apply_language("css", configured.css or "green")
  apply_language("markdown", configured.markdown or "beige")
  apply_language("markdown_inline", configured.markdown or "beige")

  return mode
end

function M.get_mode()
  return mode
end

function M.set_mode(next_mode)
  validate_mode(next_mode)
  mode = next_mode

  if vim.g.colors_name == "argiope" then
    M.apply()
  end

  return mode
end

function M.toggle()
  if mode == "monochrome" then
    return M.set_mode("hybrid")
  end
  return M.set_mode("monochrome")
end

return M
