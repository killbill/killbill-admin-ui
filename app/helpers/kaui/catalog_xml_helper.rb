require "rexml/document"
include REXML

module Kaui
  module CatalogXmlHelper

    def format_xml(unformatted_xml)


      # Start by removing all spaces before using rexml
      unformatted_xml.gsub!(/>\s+</, "><")

      result = ""
      pdoc = Document.new(unformatted_xml)
      formatter = REXML::Formatters::Pretty.new(4)
      formatter.compact = true
      formatter.write(pdoc, result)
      result
    end
  end
end

