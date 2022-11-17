module Kramdown

  module Converter

    class Indesign

      class Style

        attr_accessor :name
        attr_accessor :attrs
        attr_accessor :based_on

        def initialize(name:, attrs: nil, based_on: nil)
          @name = name
          @attrs = attrs || {}
          @based_on = based_on
        end

        def build(xml)
          xml.send(self.class.type, Self: to_s, Name: @name, **attrs) do
            if @based_on
              xml.Properties do
                xml.BasedOn(@based_on.to_s, type: 'object')
              end
            end
          end
        end

        def to_s
          "#{self.class.type}/#{@name}"
        end

      end

      class ParagraphStyle < Style

        def self.type
          'ParagraphStyle'
        end

      end

      class CharacterStyle < Style

        def self.type
          'CharacterStyle'
        end

      end

    end

  end

end