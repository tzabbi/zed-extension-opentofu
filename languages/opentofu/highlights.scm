; highlights.scm — OpenTofu for Zed
; Based on nvim-treesitter queries for HCL and Terraform,
; adapted and extended for OpenTofu and Zed's capture names.

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

; ── Top-level block type keywords (resource, data, …) ────
(body
  (block
    (identifier) @keyword))

; ── Nested block labels (e.g. provisioner, lifecycle, …) ─
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
; { key: val } — highlight identifier keys as properties
(object_elem
  key:
    (expression
      (variable_expr
        (identifier) @property)))

; ── Property access (get_attr) ────────────────────────────
; var.foo, data.bar, each.value, manifest.kind, etc.
; The property part (after the dot) is highlighted as @property
(expression
  (variable_expr
    (identifier) @variable)
  (get_attr
    (identifier) @property))

; ── For-loop iteration variables ──────────────────────────
; for <var> in ... :
; for <key>, <value> in ... :
(for_intro
  (identifier) @variable.parameter)

; ── Built-in reference variables ──────────────────────────
; each.value, each.key
(expression
  (variable_expr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "each" "self" "count"))
  (get_attr
    (identifier) @property))

; each / self / count standalone (without get_attr)
((variable_expr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "each" "self" "count")))

; ── OpenTofu / Terraform well-known references ────────────
; local/module/data/var/output — the prefix is a builtin
(expression
  (variable_expr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "data" "var" "local" "module" "output"))
  (get_attr
    (identifier) @property))

; ── path.root / path.cwd / path.module ────────────────────
(expression
  (variable_expr
    (identifier) @type
    (#eq? @type "path"))
  (get_attr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "root" "cwd" "module")))

; ── opentofu.workspace ────────────────────────────────────
(expression
  (variable_expr
    (identifier) @type
    (#eq? @type "opentofu"))
  (get_attr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "workspace")))

; ── terraform.workspace (backwards compat) ────────────────
(expression
  (variable_expr
    (identifier) @type
    (#eq? @type "terraform"))
  (get_attr
    (identifier) @variable.builtin
    (#any-of? @variable.builtin "workspace")))

; ── Type keywords ─────────────────────────────────────────
; TODO: ideally only for identifiers under a `variable` block
((identifier) @type
  (#any-of? @type "bool" "string" "number" "object" "tuple" "list" "map" "set" "any"))

(object_elem
  val:
    (expression
      (variable_expr
        (identifier) @type
        (#any-of? @type "bool" "string" "number" "object" "tuple" "list" "map" "set" "any"))))
