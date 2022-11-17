require 'kramdown'
require 'nokogiri'

module Kramdown

  module Converter

    class Indesign < Base

      class Error < StandardError; end

      def initialize(root, options)
        super
        @paragraph_style_group = make_paragraph_styles
        @character_style_group = make_character_styles
        root.setup_tree
      end

      def make_paragraph_styles
        base_style = ParagraphStyle.new(name: '$ID/NormalParagraphStyle')
        group = ParagraphStyleGroup.new(base_style: base_style)
        group.add_styles(
          'head1' => {},
          'head2' => {},
          'head3' => {},
          'para' => {},
          'para first' => { based_on: 'para' },
          'bul item' => {},
          'num item' => {},
          'footnote' => {},
          'blockquote' => {},
          'credit' => {},
        )
        group
      end

      def make_character_styles
        base_style = CharacterStyle.new(name: '$ID/[No character style]')
        group = CharacterStyleGroup.new(base_style: base_style)
        group.add_styles(
          'bold' => { attrs: { FontStyle: 'Bold' } },
          'italic' => { attrs: { FontStyle: 'Italic' } },
          'small caps' => { attrs: { Capitalization: 'CapToSmallCap' } },
          'code' => { attrs: {} },  #FIXME: mono font
          'footnote ref' => { },   #FIXME: OpenType superior
        )
        group
      end

      def convert(elem, options={})
# ;;puts elem
        begin
          method_name = "convert_#{elem.type}"
          raise Error, "Can't convert element" unless respond_to?(method_name)
          send(method_name, elem)
        rescue Error => e
          raise Error, "#{e} (type: #{elem.type.inspect}, value: #{elem.value.inspect}, location: #{elem.options[:location]})"
        end
      end

      def convert_children(elem)
        elem.children.each do |e|
          if e.is_text? && @xml.parent.name != 'Content'
            build_character(@character_style_group.base_style) { convert(e) }
          else
            convert(e)
          end
        end
      end

      def convert_root(elem)
        Nokogiri::XML::Builder.new do |xml|
          @xml = xml
          build_document do
            convert_children(elem)
          end
        end.doc.to_xml(save_with: 0)
      end

      def convert_xml_comment(elem)
        # ignore
      end

      def convert_html_element(elem)
        if elem.value == 'a'
          convert_a(elem)
        else
          raise Error, "Unsupported HTML element: <#{elem.value}>"
        end
      end

      def convert_header(elem)
        build_paragraph("head#{elem.options[:level]}") { convert_children(elem) }
      end

      def convert_p(elem)
        style = elem.ial_class \
          || @next_paragraph_style \
          || (@previous_paragraph_style && @previous_paragraph_style.name.start_with?('head') && 'para first') \
          || 'para'
        build_paragraph(style) { convert_children(elem) }
      end

      def convert_blockquote(elem)
        @next_paragraph_style = 'blockquote'
        convert_children(elem)
        @next_paragraph_style = nil
      end

      def convert_footnote(elem)
        build_character('footnote ref', 'Footnote') do
          convert(elem.value)
        end
      end

      def convert_footnote_def(elem)
        elem.children.each_with_index do |e, i|
          build_paragraph('footnote') do
            if i == 0
              build_character('footnote ref') do
                @xml.processing_instruction('ACE', '4')
              end
            end
            convert_children(e)
          end
        end
      end

      def convert_em(elem)
        style = case elem.ial_class
        when 'sc'
          'small caps'
        else
          'italic'
        end
        build_character(style) { convert_children(elem) }
      end

      def convert_strong(elem)
        build_character('bold') { convert_children(elem) }
      end

      def convert_codespan(elem)
        build_character('code') { @xml.text(elem.value) }
      end

      def convert_ul(elem)
        @next_paragraph_style = 'bul item'
        convert_children(elem)
        @next_paragraph_style = nil
      end

      def convert_ol(elem)
        @next_paragraph_style = 'num item'
        convert_children(elem)
        @next_paragraph_style = nil
      end

      def convert_li(elem)
        # handled in convert_p
        @xml.Br
        convert_children(elem)
      end

      def convert_br(elem)
        # newline automatically inserted
      end

      def convert_hr(elem)
        # paragraph_style('section')
        # @xml.text('* * *')
      end

      def convert_a(elem)
        # link ignored
        convert_children(elem)
      end

      def convert_blank(elem)
        @xml.Br
      end

      def convert_text(elem)
        @xml.text(elem.value)
      end

      def convert_entity(elem)
        @xml << "&#{elem.value.name};"
      end

      def convert_smart_quote(elem)
        text = case elem.value
        when :lsquo
          '‘'
        when :rsquo
          '’'
        when :ldquo
          '“'
        when :rdquo
          '”'
        else
          raise "Unknown smart quote: #{elem.value.inspect}"
        end
        @xml.text(text)
      end

      def convert_typographic_sym(elem)
        text = case elem.value
        when :ndash
          '–'
        when :hellip
          '…'
        else
          raise "Unknown typographic symbol: #{elem.value.inspect}"
        end
        @xml.text(text)
      end

      ###

      def build_document(&block)
        @xml.processing_instruction('aid', 'style="50" type="snippet" readerVersion="6.0" featureSet="513" product="8.0(370)"')
        @xml.processing_instruction('aid', 'SnippetType="InCopyInterchange"')
        @xml.Document(DOMVersion: '8.0', Self: 'doc') do
          @character_style_group.build(@xml)
          @paragraph_style_group.build(@xml)
          build_story(&block)
        end
      end

      def build_story(&block)
        @xml.Story(Self: 'story') do
          @xml.StoryPreference(OpticalMarginAlignment: true, OpticalMarginSize: 12)
          yield
        end
      end

      def build_paragraph(style, &block)
        style = @paragraph_style_group[style] unless style.kind_of?(Style)
        @xml.ParagraphStyleRange(AppliedParagraphStyle: style, &block)
        @previous_paragraph_style = style
      end

      def build_character(style, sub_name='Content', &block)
        style = @character_style_group[style] unless style.kind_of?(Style)
        @xml.CharacterStyleRange(AppliedCharacterStyle: style) do
          @xml.send(sub_name, &block)
        end
      end

    end

  end

end

require_relative 'kramdown-converter-indesign/style'
require_relative 'kramdown-converter-indesign/style_group'
require_relative 'kramdown-converter-indesign/extensions/kramdown'
require_relative 'kramdown-converter-indesign/extensions/nokogiri'