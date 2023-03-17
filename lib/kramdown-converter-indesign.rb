require 'kramdown'
require 'indesign'

require_relative 'kramdown-converter-indesign/extensions/kramdown'
require_relative 'kramdown-converter-indesign/extensions/kramdown-options'

module Kramdown

  module Converter

    class Indesign < Base

      ParagraphStyles = {
        head1: nil,
        head2: nil,
        head3: nil,
        para: nil,
        para0: { base: :para },
        section: nil,
        blockquote: nil,
        verse: nil,
        attribution: nil,
        telegram: nil,
        code: nil,
        dl_item: nil,
        ol_item: nil,
        ul_item: nil,
      }

      CharacterStyles = {
        b: { FontStyle: 'Bold' },
        i: { FontStyle: 'Medium Italic' },
        sc: { Capitalization: 'CapToSmallCap' },
        frac: { OTFFraction: true },
        code: nil,  #FIXME: mono font
        footnote_ref: { Position: 'OTSuperscript' },
        dt: nil,
        dd: nil,
      }

      def self.convert_files(files, styles: nil)
        icml = nil
        files.each do |file|
          input = File.read(file)
          input.strip!
          input += "\n\n" unless file == files.last
          begin
            doc = Document.new(input, indesign_icml: icml)
            icml = doc.to_indesign
          rescue Error => e
            raise Error, "#{file}: #{e}"
          end
        end
        icml
      end

      def initialize(root, options)
        super
        @style_set = InDesign::StyleSet.new(
          paragraph_styles: ParagraphStyles,
          character_styles: CharacterStyles)
        @base_icml = options[:indesign_icml]
        root.setup_tree
      end

      def style(name)
        @style_set.paragraph_style(name)
      end

      def convert(elem, options={})
# ;;puts elem
        method = "convert_#{elem.type}"
        unless respond_to?(method)
          raise Error, "Can't convert element: #{elem.type} (location: #{elem.options[:location]})"
        end
        begin
          send(method, elem)
        rescue Error => e
          raise Error, "#{e} (type: #{elem.type.inspect}, value: #{elem.value.inspect}, location: #{elem.options[:location]})"
        end
      end

      def convert_children(elem)
        elem.children.each { |e| convert(e) }
      end

      def convert_root(elem)
        icml = InDesign::ICML.new(style_set: @style_set)
        icml.build_story do |story|
          @story = story
          convert_children(elem)
        end
        if @base_icml
          @base_icml.append(icml)
          @base_icml
        else
          icml
        end
      end

      def convert_xml_comment(elem)
        # ignore
      end

      def convert_html_element(elem)
        case elem.value
        when 'a'
          convert_a(elem)
        when 'br'
          convert_br(elem)
        else
          raise Error, "Unsupported HTML element: <#{elem.value}>"
        end
      end

      def convert_header(elem)
        style_name = :"head#{elem.options[:level]}"
        @story.paragraph(style(style_name)) do
          convert_children(elem)
        end
      end

      def convert_p(elem)
        if elem.options[:transparent]
          convert_children(elem)
        else
          style_name =
            elem.ial_class ||
            (@story.previous_paragraph_style && @story.previous_paragraph_style.name.to_s =~ /^head\d+$/ && :para0) || \
            :para
          @story.paragraph(style(style_name)) do
            convert_children(elem)
          end
        end
      end

      def convert_blockquote(elem)
        @story.paragraph(elem.ial_class&.to_sym || :blockquote) do
          convert_children(elem)
        end
      end

      def convert_footnote(elem)
        @story.character(:footnote_ref, 'Footnote') do
          convert(elem.value)
        end
      end

      def convert_footnote_def(elem)
        @story.paragraph(:footnote) do
          elem.children.each do |e|
            @story.paragraph do
              if e.is_first_child?
                @story.character(:footnote_ref) { @story.add_footnote_ref }
              end
              convert_children(e)
            end
          end
        end
      end

      def convert_em(elem)
        @story.character(elem.ial_class&.to_sym || :i) do
          convert_children(elem)
        end
      end

      def convert_strong(elem)
        @story.character(:b) do
          convert_children(elem)
        end
      end

      def convert_codespan(elem)
        @story.character(:code) do
          @story << elem.value
        end
      end

      def convert_codeblock(elem)
        @story.break_line
        @story.paragraph(elem.ial_class&.to_sym || :code) do
          @story << elem.value
        end
      end

      def convert_ul(elem)
        @list_item_style = :ul_item
        convert_children(elem)
        @list_item_style = nil
      end

      def convert_ol(elem)
        @list_item_style = :ol_item
        convert_children(elem)
        @list_item_style = nil
      end

      def convert_li(elem)
        @story.break_line unless elem.is_first_child?
        @story.paragraph(@list_item_style) do
          convert_children(elem)
        end
      end

      def convert_dl(elem)
        0.step(to: elem.children.length - 1, by: 2) do |i|
          dt, dd = elem.children[i], elem.children[i + 1]
          @story.paragraph(style(:dl_item)) do
            @story.break_line unless dt.is_first_child?
            @story.character(:dt) do
              convert_children(dt)
            end
            @story.add_tab
            @story.character(:dd) do
              convert_children(dd)
            end
          end
        end
      end

      def convert_br(elem)
        @story << "\u2028"     # line separarator
      end

      def convert_hr(elem)
        @story.paragraph(style(:section))
      end

      def convert_a(elem)
        # link ignored
        convert_children(elem)
      end

      def convert_blank(elem)
        @story.break_line
      end

      def convert_text(elem)
        @story << elem.value \
          .gsub(/\n/, '')
          .gsub(%r{(\d+) (\d+/\d+)}, "\\1\u2009\\2")    # THIN SPACE between fraction whole number and fraction
      end

      def convert_entity(elem)
        @story << elem.value.name.to_sym
      end

      def convert_smart_quote(elem)
        @story << elem.value
      end

      def convert_typographic_sym(elem)
        @story << elem.value
      end

    end

  end

end