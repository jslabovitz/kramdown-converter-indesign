module Kramdown

  module Converter

    class Indesign

      class StyleGroup

        attr_accessor :id
        attr_accessor :base_style

        def self.add_styles(specs)
          new.tap { |g| g.add_styles(specs) }
        end

        def initialize(base_style:, id: nil)
          @id = id || self.class.default_id
          @base_style = base_style
          @styles = {}
        end

        def add_styles(specs)
          specs.each do |name, spec|
            add_style(spec.merge(name: name))
          end
        end

        def add_style(params)
          params = params.dup
          if (base = params[:based_on])
            base = self[base] if base.kind_of?(String)
          end
          params[:based_on] = base || @base_style
          style = self.class.style_class.new(**params)
          @styles[style.name] = style
          style
        end

        def [](name)
          @styles[name] or raise "Can't find style: #{name}"
        end

        def build(xml)
          xml.send(self.class.xml_tag, Self: @id) do
            @base_style.build(xml) if @base_style
            @styles.values.each do |style|
              style.build(xml)
            end
          end
        end

      end

      class ParagraphStyleGroup < StyleGroup

        def self.style_class
          ParagraphStyle
        end

        def self.xml_tag
          'RootParagraphStyleGroup'
        end

        def self.default_id
          'paragraph_styles'
        end

      end

      class CharacterStyleGroup < StyleGroup

        def self.style_class
          CharacterStyle
        end

        def self.xml_tag
          'RootCharacterStyleGroup'
        end

        def self.default_id
          'character_styles'
        end

      end

    end

  end

end