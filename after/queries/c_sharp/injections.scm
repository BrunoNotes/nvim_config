; extends

((variable_declaration
    (variable_declarator
      name: (identifier) @_identifier
      (string_literal (string_literal_content) @injection.content)))
 (#contains? @_identifier "query")
 (#set! injection.language "sql"))
