-- Server-side HTML rendering for Argiope source.  This deliberately uses the
-- same parser aliases, queries, predicates, and normalized template passes as
-- the editor integration; it is not a second highlighter.
local injections = require("argiope.injections")
local model = require("argiope.model")
local palette = require("argiope.palette")
local theme = require("argiope.theme")

local M = {}

local shades = {
  "darkest",
  "dim",
  "muted",
  "soft",
  "main",
  "accent",
  "bright",
  "light",
  "gray_dim",
  "gray",
  "gray_light",
  "gray_warm",
}

local tones = vim.list_extend(vim.deepcopy(shades), { "comment" })
local tone_index = {}
for index, tone in ipairs(tones) do
  tone_index[tone] = index - 1
end

local families = {
  javascript = "j",
  argiope_javascript = "e",
  html = "h",
  argiope_html = "h",
  css = "c",
  markdown = "m",
  markdown_inline = "m",
}

local default_shade = {
  j = "main",
  e = "main",
  h = "light",
  c = "main",
  m = "gray",
}

local palette_option = {
  j = "javascript",
  e = "javascript_embedded",
  h = "html",
  c = "css",
  m = "markdown",
}

local editor_tones = {
  "fg",
  "comment",
  "purple",
  "yellow",
  "cyan",
  "green",
  "pink",
  "orange",
  "beige",
  "golden_yellow",
  "string_gray",
  "nontext",
}

local editor_tone_index = {}
for index, tone in ipairs(editor_tones) do
  editor_tone_index[tone] = index - 1
end

local function lines_from(source)
  if type(source) == "table" then
    for _, line in ipairs(source) do
      if type(line) ~= "string" then
        error("argiope.render: source lines must be strings")
      end
    end
    return vim.deepcopy(source)
  end
  if type(source) ~= "string" then
    error("argiope.render: source must be a string or a list of strings")
  end
  return vim.split(source, "\n", { plain = true })
end

local function offsets_for(lines)
  local offsets = {}
  local offset = 0
  for row, line in ipairs(lines) do
    offsets[row - 1] = offset
    offset = offset + #line
    if row < #lines then
      offset = offset + 1
    end
  end
  return offsets, offset
end

local function absolute_offset(offsets, row, col)
  return (offsets[row] or 0) + col
end

local function escape_html(value)
  return value:gsub('[&<>"]', {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
  })
end

local function language_class(language)
  return "lang-" .. language:lower():gsub("[^a-z0-9_-]", "-")
end

local function language_for_style(language)
  if language == "argiope_html" then
    return "html"
  end
  if language == "markdown_inline" then
    return "markdown"
  end
  return language
end

local function add_span(spans, span)
  if span.finish > span.start then
    span.sequence = #spans + 1
    table.insert(spans, span)
  end
end

local function capture_range(node, source, metadata)
  local start_row, start_col, _, end_row, end_col =
    unpack(vim.treesitter.get_range(node, source, metadata))
  return start_row, start_col, end_row, end_col
end

local function collect_query_spans(bufnr, language, source, offsets, total, spans)
  local parser = assert(vim.treesitter.get_parser(bufnr, language))
  parser:for_each_tree(function(tree, language_tree)
    local language = language_tree:lang()
    local query = vim.treesitter.query.get(language, "highlights")
    if not query then
      return
    end

    for capture_id, node, metadata in query:iter_captures(tree:root(), source, 0, -1) do
      local capture = query.captures[capture_id]
      if capture:sub(1, 1) ~= "_" then
        local start_row, start_col, end_row, end_col =
          capture_range(node, source, (metadata or {})[capture_id])
        add_span(spans, {
          start = math.max(0, absolute_offset(offsets, start_row, start_col)),
          finish = math.min(total, absolute_offset(offsets, end_row, end_col)),
          language = language,
          capture = capture,
          node_type = node:type(),
          priority = tonumber(
            metadata and (metadata.priority or metadata[capture_id] and metadata[capture_id].priority)
          ) or vim.hl.priorities.treesitter,
        })
      end
    end
  end)
end

local function collect_normalized_spans(bufnr, lines, offsets, total, spans, module)
  for row, row_spans in pairs(module._spans(bufnr)) do
    for _, span in ipairs(row_spans) do
      local capture, language = span.group:match("^@(.+)%.([^.]+)$")
      if capture and language then
        add_span(spans, {
          start = math.max(0, absolute_offset(offsets, row, span.start_col)),
          finish = math.min(total, absolute_offset(offsets, row, span.end_col)),
          language = language,
          capture = capture,
          priority = span.priority,
        })
      end
    end
  end
end

local function subtract_ranges(start, finish, exclusions)
  local ranges = { { start, finish } }
  for _, exclusion in ipairs(exclusions) do
    local remaining = {}
    for _, range in ipairs(ranges) do
      if exclusion[2] <= range[1] or exclusion[1] >= range[2] then
        table.insert(remaining, range)
      else
        if exclusion[1] > range[1] then
          table.insert(remaining, { range[1], exclusion[1] })
        end
        if exclusion[2] < range[2] then
          table.insert(remaining, { exclusion[2], range[2] })
        end
      end
    end
    ranges = remaining
  end
  return ranges
end

-- A language tree gives Neovim an @none fallback for otherwise uncaptured
-- text. Recreate that fallback over each literal fragment so prose inside an
-- HTML template does not inherit JavaScript's string colour.
local function collect_family_spans(bufnr, offsets, total)
  local spans = {}
  for _, template in ipairs(model.templates(bufnr) or {}) do
    if template.registered then
      local family = families[template.language]
      local start_row, start_col, end_row, end_col = unpack(template.range)
      local start = absolute_offset(offsets, start_row, start_col + 1)
      local finish = absolute_offset(offsets, end_row, end_col - (template.closed and 1 or 0))
      local exclusions = {}
      for _, child in ipairs(template.node:named_children()) do
        if child:type() == "template_substitution" then
          local sub_start_row, sub_start_col, sub_end_row, sub_end_col = child:range()
          table.insert(exclusions, {
            absolute_offset(offsets, sub_start_row, sub_start_col),
            absolute_offset(offsets, sub_end_row, sub_end_col),
          })
        end
      end
      for _, range in ipairs(subtract_ranges(start, finish, exclusions)) do
        add_span(spans, {
          start = math.max(0, range[1]),
          finish = math.min(total, range[2]),
          family = family,
          priority = 1,
        })
      end
    end
  end
  return spans
end

local function winner_at(spans, position)
  local winner
  for _, span in ipairs(spans) do
    if position >= span.start and position < span.finish then
      if
        not winner
        or span.priority > winner.priority
        or (span.priority == winner.priority and span.sequence > winner.sequence)
      then
        winner = span
      end
    end
  end
  return winner
end

local function family_at(spans, position, fallback)
  local winner
  for _, span in ipairs(spans) do
    if position >= span.start and position < span.finish then
      if not winner or span.priority >= winner.priority then
        winner = span
      end
    end
  end
  return winner and winner.family or fallback
end

local function classes_for(span, native)
  if not span then
    return nil
  end
  local capture = span.node_type and span.node_type:find("comment", 1, true)
      and "comment"
    or span.capture
  local style = native and theme.editor_capture_style(capture)
    or theme.capture_style(language_for_style(span.language), capture)
  local classes = {
    native and "g" .. editor_tone_index[style.tone]
      or "t" .. tone_index[style.tone],
  }
  if style.bold then
    table.insert(classes, "b")
  end
  if style.italic then
    table.insert(classes, "i")
  end
  if style.strikethrough then
    table.insert(classes, "s")
  end
  if style.underline then
    table.insert(classes, "u")
  end
  return table.concat(classes, " ")
end

local function render_html(
  source,
  spans,
  family_spans,
  root_family,
  native,
  allow_captured_families,
  language
)
  local points = { 0, #source }
  for _, span in ipairs(spans) do
    table.insert(points, span.start)
    table.insert(points, span.finish)
  end
  for _, span in ipairs(family_spans) do
    table.insert(points, span.start)
    table.insert(points, span.finish)
  end
  table.sort(points)

  local segments = {}
  local previous = -1
  for _, point in ipairs(points) do
    if point ~= previous and point > previous then
      local start = previous < 0 and 0 or previous
      if point > start then
        local literal_family = family_at(family_spans, start, root_family)
        local family = literal_family
        local winner = winner_at(spans, start)
        local captured_family = winner and families[winner.language] or nil
        if allow_captured_families and family == "j" then
          family = captured_family or family
        elseif allow_captured_families and captured_family and captured_family ~= "j" then
          family = captured_family
        end

        -- The host JavaScript query captures every string_fragment beneath an
        -- injected template. Neovim's child language has an @none fallback
        -- there, so do not let that underlying string capture turn ordinary
        -- HTML/CSS/Markdown text into a semantic token in the renderer.
        if
          allow_captured_families
          and literal_family ~= "j"
          and winner
          and winner.language == "javascript"
        then
          winner = nil
        end

        local classes = classes_for(winner, native)
        local text = source:sub(start + 1, point)
        local previous_segment = segments[#segments]
        if
          previous_segment
          and previous_segment.family == family
          and previous_segment.classes == classes
        then
          previous_segment.text = previous_segment.text .. text
        else
          table.insert(segments, {
            family = family,
            classes = classes,
            text = text,
          })
        end
      end
    end
    previous = point
  end
  local root_class = root_family
  local output = {
    '<pre class="a ' .. root_class .. " " .. language_class(language) .. '"><code>',
  }
  local active_family = root_family
  for _, segment in ipairs(segments) do
    if segment.family ~= active_family then
      if active_family ~= root_family then
        table.insert(output, "</span>")
      end
      if segment.family ~= root_family then
        table.insert(output, '<span class="' .. segment.family .. '">')
      end
      active_family = segment.family
    end
    local text = escape_html(segment.text)
    if segment.classes then
      table.insert(output, '<span class="' .. segment.classes .. '">' .. text .. "</span>")
    else
      table.insert(output, text)
    end
  end
  if active_family ~= root_family then
    table.insert(output, "</span>")
  end
  table.insert(output, "</code></pre>")
  return table.concat(output)
end

local function family_palette(family, variant, configured)
  configured = configured or palette_option[family]
  local profile = assert(palette.profile(variant))
  local language = assert(profile.languages[configured], "missing language palette " .. configured)
  return language.colors, configured
end

local tone_language = {
  j = "javascript",
  e = "argiope_javascript",
  h = "html",
  c = "css",
  m = "markdown",
}

function M.css(options)
  options = options or {}
  if type(options) ~= "table" then
    error("argiope.render: CSS options must be a table")
  end
  local variant = options.variant or theme.get_variant()
  local profile = palette.profile(variant)
  if not profile then
    error(("argiope.render: unknown theme variant %q"):format(tostring(variant)))
  end
  local rules = {
    ("pre.a{--a-bg:%s;background:var(--a-bg);color:%s;overflow:auto}pre.a code{font-family:inherit}"):format(
      profile.base.bg,
      profile.base.fg
    ),
  }
  for _, family in ipairs({ "j", "e", "h", "c", "m" }) do
    local colors = family_palette(family, variant)
    local variables = {}
    for index, tone in ipairs(tones) do
      local resolved = theme.resolve_capture_tone(tone_language[family], tone, variant)
      table.insert(variables, ("--a-t%d:%s"):format(index - 1, colors[resolved.shade]))
    end
    table.insert(
      rules,
      (".a.%s,.a .%s{%s;color:%s}"):format(
        family,
        family,
        table.concat(variables, ";"),
        colors[default_shade[family]]
      )
    )
  end
  -- t0..t12 are stable semantic tones. The first twelve retain the compact
  -- palette ladder; t12 is the comment role whose interpretation may differ
  -- by theme without changing the rendered HTML.
  for index, tone in ipairs(tones) do
    table.insert(rules, (".a .t%d{color:var(--a-t%d)}"):format(index - 1, index - 1))
  end
  local generic = {}
  for index, tone in ipairs(editor_tones) do
    generic[index] = profile.base[tone]
  end
  local generic_variables = {}
  for index, color in ipairs(generic) do
    table.insert(generic_variables, "--a-g" .. (index - 1) .. ":" .. color)
    table.insert(rules, ".a .g" .. (index - 1) .. "{color:var(--a-g" .. (index - 1) .. ")}")
  end
  table.insert(rules, ".a.g,.a.k{" .. table.concat(generic_variables, ";") .. "}")
  table.insert(rules, ".a.j.k{color:var(--a-g0)}")
  table.insert(rules, ".a .b{font-weight:700}.a .i{font-style:italic}.a .s{text-decoration:line-through}.a .u{text-decoration:underline}")
  return table.concat(rules)
end

function M.html(source, options)
  options = options or {}
  if type(options) ~= "table" then
    error("argiope.render: options must be a table")
  end
  local language = options.language or "javascript"
  if type(language) ~= "string" or language == "" then
    error("argiope.render: options.language must be a non-empty parser language")
  end
  local variant = options.variant or theme.get_variant()
  local profile = palette.profile(variant)
  if not profile then
    error(("argiope.render: unknown theme variant %q"):format(tostring(variant)))
  end
  local palette_name = options.palette
  if palette_name ~= nil and profile.languages[palette_name] == nil then
    error(("argiope.render: theme has no language palette %q"):format(palette_name))
  end
  local lines = lines_from(source)
  local text = table.concat(lines, "\n")
  local offsets, total = offsets_for(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)

  local ok, result = xpcall(function()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    if language == "javascript" then
      injections.install()
      local attached, err = require("argiope.highlight").attach(bufnr)
      assert(attached, err)
    else
      vim.treesitter.start(bufnr, language)
    end
    assert(vim.treesitter.get_parser(bufnr, language):parse(true))

    local spans = {}
    collect_query_spans(bufnr, language, bufnr, offsets, total, spans)
    if language == "javascript" then
      collect_normalized_spans(bufnr, lines, offsets, total, spans, require("argiope.html"))
      collect_normalized_spans(bufnr, lines, offsets, total, spans, require("argiope.markdown"))
      return render_html(
        text,
        spans,
        collect_family_spans(bufnr, offsets, total),
        "j",
        false,
        true,
        language
      )
    end
    if palette_name then
      local palette_family = families[palette_name]
        or palette_name == "javascript_embedded" and "e"
        or "j"
      return render_html(
        text,
        spans,
        {},
        palette_family,
        false,
        palette_name == "html",
        language
      )
    end
    return render_html(text, spans, {}, "g", true, false, language)
  end, debug.traceback)

  if language == "javascript" then
    require("argiope.highlight").detach(bufnr)
  else
    pcall(vim.treesitter.stop, bufnr)
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
  if not ok then
    error(result, 0)
  end
  return result
end

function M.render(source, options)
  local variant = options and options.variant or nil
  return {
    html = M.html(source, options),
    css = M.css({ variant = variant }),
  }
end

return M
