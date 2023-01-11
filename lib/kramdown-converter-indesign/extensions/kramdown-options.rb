module Kramdown

  module Options

    define(:indesign_idml_input, String, '', <<~EOF)
      The name of an IDML file that will be used as a template
      to generate a new IDML file.

      Default: ''
      Used by: indesign
    EOF

    define(:indesign_idml_output, String, '', <<~EOF)
      The name of an IDML file that will be used as the name
      of a new IDML file.

      Default: ''
      Used by: indesign
    EOF

    define(:indesign_idml_story_id, String, nil, <<~EOF)
      The ID of the story to be replaced within the specified IDML file.

      Default: nil
      Used by: indesign
    EOF

    define(:indesign_append_to_icml, Object, nil, <<~EOF) do |val|
      An existing ICML object to add to.

      Default: nil
      Used by: indesign
    EOF
      raise Kramdown::Error, "Must provide InDesign::ICML object: #{val.class}" if val && !val.kind_of?(InDesign::ICML)
      val
    end

  end

end