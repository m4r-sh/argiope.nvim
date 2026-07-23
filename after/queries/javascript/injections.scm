; extends

; Keep JavaScript's existing injections while adding interpolation-aware
; tagged-template regions. `injection.combined` keeps all string fragments in
; one embedded parse while excluding template_substitution nodes.

; Argiope disables the equivalent upstream generic-tag patterns at runtime and
; reinstates them here for tags whose registered language it does not manage.
; This preserves third-party injections without parsing Argiope templates
; twice.
(call_expression
  function: (identifier) @injection.language
  arguments: [
    (arguments
      (template_string) @injection.content)
    (template_string) @injection.content
  ]
  (#argiope-unmanaged? @injection.language)
  (#lua-match? @injection.language "^[a-zA-Z][a-zA-Z0-9]*$")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#not-any-of? @injection.language "svg" "css"))

(call_expression
  function: ((identifier) @_argiope_upstream_name
    (#argiope-unmanaged? @_argiope_upstream_name)
    (#any-of? @_argiope_upstream_name "css" "keyframes"))
  arguments: ((template_string) @injection.content
    (#offset! @injection.content 0 1 0 -1)
    (#set! injection.include-children)
    (#set! injection.language "styled")))

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
