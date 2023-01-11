require 'kramdown'
require 'indesign'

require_relative 'kramdown-converter-indesign/extensions/kramdown'
require_relative 'kramdown-converter-indesign/extensions/kramdown-options'

module Kramdown

  module Converter

    class Indesign < Base

      def initialize(root, options)
        super
        root.setup_tree
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
        if (input_file = options[:indesign_idml_input]) && !input_file.empty?
          output_file = options[:indesign_idml_output]
          raise "Must specify --indesign-idml-output with output file" if output_file.empty?
          idml = InDesign::IDML.load(input_file)
          @story = InDesign::Story.new
          @story.build { convert_children(elem) }
          story_id = options[:indesign_idml_story_id]
          story_id = idml.story_ids.first if story_id.empty?
          idml.replace_story(story_id, @story)
          idml.save(output_file)
        else
          icml = InDesign::ICML.new
          icml.story do |story|
            @story = story
            convert_children(elem)
          end
          icml.to_xml(format: options[:format])
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
        @story.head(elem.options[:level], elem.ial_class) { convert_children(elem) }
      end

      def convert_p(elem)
        @story.para(elem.ial_class) { convert_children(elem) }
      end

      def convert_blockquote(elem)
        @story.blockquote { convert_children(elem) }
      end

      def convert_footnote(elem)
        @story.footnote { convert(elem.value) }
      end

      def convert_footnote_def(elem)
        elem.children.each do |e|
          @story.footnote_def(e == elem.children.first) { convert_children(e) }
        end
      end

      def convert_em(elem)
        case elem.ial_class
        when 'sc'
          @story.small_caps { convert_children(elem) }
        else
          @story.italic { convert_children(elem) }
        end
      end

      def convert_strong(elem)
        @story.bold { convert_children(elem) }
      end

      def convert_codespan(elem)
        @story.code { @story << elem.value }
      end

      def convert_ul(elem)
        elem.children.each_with_index do |e, i|
          @story.break_line unless i == 0
          @story.bul_item do
            convert_children(e.children.first)
          end
        end
      end

      def convert_ol(elem)
        elem.children.each_with_index do |e, i|
          @story.break_line unless i == 0
          @story.num_item do
            convert_children(e.children.first)
          end
        end
      end

      def convert_li(elem)
        # handled in convert_p
        @story.break_line
        convert_children(elem)
      end

      def convert_dl(elem)
        # ;;elem.print_tree
        @story.definition_list do
          children = elem.children.dup
          until children.empty?
            dt, dd = children.shift, children.shift
            if dd.children.length == 1 && (p = dd.children.first).type == :p
              dd = p
            end
            @story.character('dt') do
              dt.children.each { |e| convert(e) }
            end
            @story.add_tab
            @story.character('dd') do
              dd.children.each { |e| convert(e) }
            end
            @story.break_line
          end
        end
      end

      def convert_br(elem)
        @story << "\u2028"     # line separarator
      end

      def convert_hr(elem)
        # paragraph_style('section')
        # @story << '* * *'
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
          .gsub(%r{(\d+) (\d+/\d+)}, "\\1\u2009\\2")    # THIN SPACE
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