require 'kramdown'
require 'indesign'

require_relative 'kramdown-converter-indesign/extensions/kramdown'
require_relative 'kramdown-converter-indesign/extensions/kramdown-options'

module Kramdown

  module Converter

    class Indesign < Base

      Environments = {

        ROOT: {
          head1: nil,
          head2: nil,
          head3: nil,
          para: nil,
          para0: :para,
          section: nil,
        },

        blockquote: {
          para: %i[ROOT para],
          para0: :para,
        },

        verse: {
          para: %i[ROOT para],
        },

        signature: {
          para: %i[ROOT para],
        },

        dlist: {
          item: %i[ROOT para0],
        },

        ulist: {
          item: %i[ROOT para0],
        },

        olist: {
          item: %i[ROOT para0],
        },

        footnote: {
          para: %i[ROOT para],
          para0: :para,
        },

        #FIXME
        front: {
          head1: nil,
          head2: nil,
          head3: nil,
          para: nil,
          para0: :para,
          section: nil,
        },

        back: {
          head1: nil,
          head2: nil,
          head3: nil,
          para: nil,
          para0: :para,
          section: nil,
        },

      }

      CharacterStyles = {
        b: { FontStyle: 'Bold' },
        i: { FontStyle: 'Italic' },
        sc: { Capitalization: 'CapToSmallCap' },
        frac: { OTFFraction: true },
        code: nil,  #FIXME: mono font
        footnote_ref: { Position: 'OTSuperscript' },
        term: nil,
        def: nil,
      }

      def self.convert_files(files, styles: nil)
        icml = nil
        files.each do |file|
          input = File.read(file)
          if input.sub!(/^Environment:\s+(.*?)$/i, '')
            environment_name = $1
          else
            environment_name = ''
          end
          input.strip!
          input += "\n\n" unless file == files[-1]
          doc = Document.new(input,
            indesign_icml: icml,
            indesign_environment: environment_name)
          icml = doc.to_indesign
        end
        icml
      end

      def initialize(root, options)
        super
        paragraph_styles = make_styles
        @style_set = InDesign::StyleSet.new(
          paragraph_styles: paragraph_styles,
          character_styles: CharacterStyles)
        if (name = options[:indesign_environment]) && !name.empty?
          @environment = name.to_sym
        else
          @environment = :ROOT
        end
        @base_icml = options[:indesign_icml]
        root.setup_tree
      end

      def make_styles
        styles = {}
        Environments.each do |env_name, env_styles|
          env_styles.each do |style_name, style|
            full_name = full_style_name(env_name, style_name)
            params = case style
            when nil
              {}
            when Hash
              style
            when Array
              { base: full_style_name(*style) }
            when Symbol
              { base: full_style_name(env_name, style) }
            else
              raise style.inspect
            end
            styles[full_name] = params
          end
        end
        styles
      end

      def environment(name, &block)
        previous = @environment
        @environment = name
        yield
        @environment = previous
      end

      def style(name)
        @style_set.paragraph_style(full_style_name(@environment, name))
      end

      def full_style_name(environment, style)
        if environment == :ROOT
          style.to_s
        else
          [environment, style].join(' > ')
        end
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
        environment(elem.ial_class&.to_sym || :blockquote) do
          convert_children(elem)
        end
      end

      def convert_footnote(elem)
        @story.character(:footnote_ref, 'Footnote') do
          convert(elem.value)
        end
      end

      def convert_footnote_def(elem)
        environment(:footnote) do
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

      def convert_ul(elem)
        environment(:ulist) do
          convert_children(elem)
        end
      end

      def convert_ol(elem)
        environment(:olist) do
          convert_children(elem)
        end
      end

      def convert_li(elem)
        @story.break_line unless elem.is_first_child?
        @story.paragraph(style(:item)) do
          convert_children(elem)
        end
      end

      def convert_dl(elem)
        environment(:dlist) do
          0.step(to: elem.children.length - 1, by: 2) do |i|
            dt, dd = elem.children[i], elem.children[i + 1]
            @story.paragraph(style(:item)) do
              @story.break_line unless dt.is_first_child?
              @story.character(:term) do
                convert_children(dt)
              end
              @story.add_tab
              @story.character(:def) do
                convert_children(dd)
              end
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