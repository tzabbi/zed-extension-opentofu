; https://github.com/nvim-treesitter/nvim-treesitter/blob/ce4adf11cfe36fc5b0e5bcdce0c7c6e8fbc9798a/queries/hcl/indents.scm
[
  (block)
  (object)
  (tuple)
  (function_call)
  (for_object_expr)
  (for_tuple_expr)
] @indent

[
  "]"
  "}"
  ")"
] @outdent
; https://github.com/nvim-treesitter/nvim-treesitter/blob/ce4adf11cfe36fc5b0e5bcdce0c7c6e8fbc9798a/queries/terraform/indents.scm
; inherits: hcl
