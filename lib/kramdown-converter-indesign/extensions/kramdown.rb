module Kramdown

  class Element

    attr_accessor :parent
    attr_accessor :level

    def setup_tree(parent=nil)
      @parent = parent
      @level = parent ? parent.level + 1 : 0
      @children.each { |e| e.setup_tree(self) }
    end

    def print_tree
      puts self
      @children.each { |child| child.print_tree }
    end

    def previous
      if (i = index) && i > 0
        @parent.children[i - 1]
      else
        nil
      end
    end

    def next
      if (i = index)
        @parent.children[i + 1]
      else
        nil
      end
    end

    def index
      @parent&.children.index(self)
    end

    def ial_class
      (ial = @options[:ial]) && ial['class']
    end

    TEXT_TYPES = [:text, :smart_quote, :typographic_sym, :entity]

    def is_text?
      TEXT_TYPES.include?(@type)
    end

    def is_first_child?
      self == @parent.children.first
    end

    def to_s
      "* %s%s <%p> (%s)" % [
        "\t" * (@level || 0),
        @type,
        @value,
        (@options || {}).map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
      ]
    end

  end

end