; Argiope owns tagged-template injections so JavaScript substitutions remain
; holes in the embedded region. `injection.combined` keeps all string fragments
; in one embedded parse while excluding template_substitution nodes.

(call_expression
  function: [
    (identifier) @_argiope_html_tag
    (member_expression) @_argiope_html_tag
  ]
  arguments: (template_string
    (string_fragment) @injection.content)
  (#argiope-language? @_argiope_html_tag "html")
  (#set! injection.language "html")
  (#set! injection.combined))

(call_expression
  function: [
    (identifier) @_argiope_css_tag
    (member_expression) @_argiope_css_tag
  ]
  arguments: (template_string
    (string_fragment) @injection.content)
  (#argiope-language? @_argiope_css_tag "css")
  (#set! injection.language "css")
  (#set! injection.combined))

(call_expression
  function: [
    (identifier) @_argiope_markdown_tag
    (member_expression) @_argiope_markdown_tag
  ]
  arguments: (template_string
    (string_fragment) @injection.content)
  (#argiope-language? @_argiope_markdown_tag "markdown")
  (#set! injection.language "markdown")
  (#set! injection.combined))
