; highlights.scm — HCL base for Zed
; Based on nvim-treesitter HCL highlights

; ── Operators ──────────────────────────────────────────────
[
  "!"
  "\*"
  "/"
  "%"
  "\+"
  "-"
  ">"
  ">="
  "<"
  "<="
  "=="
  "!="
  "&&"
  "||"
] @operator

; ── Brackets ──────────────────────────────────────────────
[
  "{"
  "}"
  "["
  "]"
  "("
  ")"
] @punctuation.bracket

; ── Delimiters ────────────────────────────────────────────
[
  "."
  ".*"
  ","
  "[*]"
] @punctuation.delimiter

; ── Special punctuation ───────────────────────────────────
[
  (ellipsis)
  "\?"
  "=>"
] @punctuation.special

[
  ":"
  "="
] @punctuation

; ── Keywords ──────────────────────────────────────────────
[
  "for"
  "endfor"
  "in"
  "if"
  "else"
  "endif"
] @keyword

; ── Strings ───────────────────────────────────────────────
[
  (quoted_template_start) ; "
  (quoted_template_end)   ; "
  (template_literal)      ; non-interpolation/directive content
] @string

; ── Heredoc ───────────────────────────────────────────────
[
  (heredoc_identifier) ; END
  (heredoc_start)      ; << or <<-
] @punctuation.delimiter

; ── Template interpolation / directives ───────────────────
[
  (template_interpolation_start) ; ${
  (template_interpolation_end)   ; }
  (template_directive_start)     ; %{
  (template_directive_end)       ; }
  (strip_marker)                 ; ~
] @punctuation.special

; ── Literals ──────────────────────────────────────────────
(numeric_lit) @number
(bool_lit) @boolean
(null_lit) @constant

; ── Comments ──────────────────────────────────────────────
(comment) @comment

; ── Default: all identifiers are variables ────────────────
(identifier) @variable

; ── Top-level block type keywords ─────────────────────────
(body
  (block
    (identifier) @keyword))

; ── Nested block labels ───────────────────────────────────
(body
  (block
    (body
      (block
        (identifier) @type))))

; ── Function calls ────────────────────────────────────────
(function_call
  (identifier) @function)

; ── Attribute definitions (left side of =) ────────────────
(attribute
  (identifier) @property)

; ── Object keys ───────────────────────────────────────────
(object_elem
  key:
    (expression
      (variable_expr
        (identifier) @property)))

; ── Property access (get_attr) ────────────────────────────
(expression
  (variable_expr
    (identifier) @variable)
  (get_attr
    (identifier) @property))

; ── For-loop iteration variables ──────────────────────────
(for_intro
  (identifier) @variable.parameter)
