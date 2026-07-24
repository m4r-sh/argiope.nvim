; extends

; Keep template interpolation fences independently themeable. The upstream
; JavaScript query calls these punctuation.special, which is too broad a name
; for a palette contract.
((template_substitution
  [
    "${"
    "}"
  ] @argiope.interpolation.delimiter)
  (#argiope-highlight?)
  (#set! priority 110))

; JavaScript's upstream query treats destructured ALL_CAPS bindings as plain
; variables. Promote the conventional constant spelling so the hybrid theme
; can give bindings such as LIST and OPTION their intended golden color.

([
  (identifier)
  (shorthand_property_identifier_pattern)
] @constant
  (#lua-match? @constant "^[A-Z][A-Z0-9_]*$")
  (#set! priority 110))

; Make Neovim's built-in `gc` operator use the language of each registered
; tagged template. Parser aliases cannot be registered as filetypes without
; changing which parser ordinary HTML and JavaScript buffers use, so capture
; metadata is the precise way to provide the local comment string.

((call_expression
  function: [
    (identifier) @_argiope_html_comment_tag
    (member_expression) @_argiope_html_comment_tag
  ]
  arguments: (template_string
    (string_fragment) @_argiope_html_comment_region))
  (#argiope-language? @_argiope_html_comment_tag "html")
  (#set! @_argiope_html_comment_region bo.commentstring "<!-- %s -->"))

((call_expression
  function: [
    (identifier) @_argiope_css_comment_tag
    (member_expression) @_argiope_css_comment_tag
  ]
  arguments: (template_string
    (string_fragment) @_argiope_css_comment_region))
  (#argiope-language? @_argiope_css_comment_tag "css")
  (#set! @_argiope_css_comment_region bo.commentstring "/* %s */"))

((call_expression
  function: [
    (identifier) @_argiope_markdown_comment_tag
    (member_expression) @_argiope_markdown_comment_tag
  ]
  arguments: (template_string
    (string_fragment) @_argiope_markdown_comment_region))
  (#argiope-language? @_argiope_markdown_comment_tag "markdown")
  (#set! @_argiope_markdown_comment_region bo.commentstring "<!-- %s -->"))

((call_expression
  function: [
    (identifier) @_argiope_javascript_comment_tag
    (member_expression) @_argiope_javascript_comment_tag
  ]
  arguments: (template_string
    (string_fragment) @_argiope_javascript_comment_region))
  (#argiope-language? @_argiope_javascript_comment_tag "javascript")
  (#set! @_argiope_javascript_comment_region bo.commentstring "// %s"))

; Unknown tagged templates are deliberately neutral. These patterns target
; only call-expression templates, so ordinary untagged template strings keep
; the normal JavaScript string palette. Registered tags are excluded through
; the same runtime registry used by injections and indentation.

((call_expression
  function: [
    (identifier) @argiope.unknown.tag
    (member_expression) @argiope.unknown.tag
  ]
  arguments: (template_string))
  (#argiope-unknown? @argiope.unknown.tag)
  (#set! priority 110))

((call_expression
  function: [
    (identifier) @_argiope_unknown_tag
    (member_expression) @_argiope_unknown_tag
  ]
  arguments: (template_string
    [
      (string_fragment)
      (escape_sequence)
    ] @argiope.unknown.template))
  (#argiope-unknown? @_argiope_unknown_tag)
  (#set! priority 110))

((call_expression
  function: [
    (identifier) @_argiope_unknown_tag
    (member_expression) @_argiope_unknown_tag
  ]
  arguments: (template_string
    "`" @argiope.unknown.delimiter))
  (#argiope-unknown? @_argiope_unknown_tag)
  (#set! priority 110))
