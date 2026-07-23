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
