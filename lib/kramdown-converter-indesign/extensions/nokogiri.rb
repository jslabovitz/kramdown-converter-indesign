module Nokogiri

  module XML

    class Builder

      def processing_instruction(string, content)
        insert(doc.create_processing_instruction(string, content))
      end

    end

    class Document

      def create_processing_instruction(string, content)
        Nokogiri::XML::ProcessingInstruction.new(self, string.to_s, content.to_s)
      end

    end

  end

end