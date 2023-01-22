module Kramdown

  module Options

    define(:indesign_append_to_icml, Object, nil, <<~EOF) do |val|
      An existing ICML object to add to.

      Default: nil
      Used by: indesign
    EOF
      if val && !val.kind_of?(InDesign::ICML)
        raise Kramdown::Error, "Must provide InDesign::ICML object: #{val.class}"
      end
      val
    end

    define(:indesign_environment, String, nil, <<~EOF)
      The environment to use for styles for this document.

      Default: nil
      Used by: indesign
    EOF

  end

end