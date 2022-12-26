require 'kramdown'
require 'indesign-icml'

require_relative 'kramdown-converter-indesign/extensions/kramdown'

module Kramdown

  module Converter

    class Indesign < Base

      class Error < StandardError; end

      def initialize(root, options)
        super
        @icml = InDesign::ICML.new
        root.setup_tree
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
          if e.is_text? && !@icml.in_content?
            @icml.character { convert(e) }
          else
            convert(e)
          end
        end
      end

      def convert_root(elem)
        @icml.document do
          convert_children(elem)
        end
        @icml.to_xml
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
        @icml.head(elem.options[:level]) { convert_children(elem) }
      end

      def convert_p(elem)
        @icml.para(elem.ial_class) { convert_children(elem) }
      end

      def convert_blockquote(elem)
        @icml.blockquote { convert_children(elem) }
      end

      def convert_footnote(elem)
        @icml.footnote { convert(elem.value) }
      end

      def convert_footnote_def(elem)
        elem.children.each do |e|
          @icml.footnote_def(e == elem.children.first) { convert_children(e) }
        end
      end

      def convert_em(elem)
        case elem.ial_class
        when 'sc'
          @icml.small_caps { convert_children(elem) }
        else
          @icml.italic { convert_children(elem) }
        end
      end

      def convert_strong(elem)
        @icml.bold { convert_children(elem) }
      end

      def convert_codespan(elem)
        @icml.code { @icml << elem.value }
      end

      def convert_ul(elem)
        @icml.bul_item { convert_children(elem) }
      end

      def convert_ol(elem)
        @icml.num_item { convert_children(elem) }
      end

      def convert_li(elem)
        # handled in convert_p
        @icml.break_line
        convert_children(elem)
      end

      def convert_br(elem)
        @icml.break_line
      end

      def convert_hr(elem)
        # paragraph_style('section')
        # @icml << '* * *'
      end

      def convert_a(elem)
        # link ignored
        convert_children(elem)
      end

      def convert_blank(elem)
        @icml.break_line
      end

      def convert_text(elem)
        text = elem.value.gsub(/\n/, '')
        @icml << text unless text.empty?
      end

      def convert_entity(elem)
        @icml << elem.value.name.to_sym
      end

      def convert_smart_quote(elem)
        @icml << elem.value
      end

      def convert_typographic_sym(elem)
        @icml << elem.value
      end

    end

  end

end