; extends

((script_element
    (start_tag
      (tag_name)
      (attribute
        (attribute_name)
        (quoted_attribute_value
          (attribute_value) @_identifier)))
    (raw_text) @injection.content
    )
 (#contains? @_identifier "js")
 (#set! injection.language "javascript"))

((script_element
    (start_tag
      (tag_name)
      (attribute
        (attribute_name)
        (quoted_attribute_value
          (attribute_value) @_identifier)))
    (raw_text) @injection.content
    )
 (#contains? @_identifier "ts")
 (#set! injection.language "typescript"))
