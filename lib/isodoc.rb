require_relative "isodoc/version"

require "nokogiri"
require "asciimath"
require "xml/xslt"
require "uuidtools"
require "base64"
require "mime/types"
require "image_size"
require_relative "isodoc/iso2wordhtml"
require_relative "isodoc/postprocessing"
require_relative "isodoc/utils"
require_relative "isodoc/metadata"
require_relative "isodoc/section"
require_relative "isodoc/references"
require_relative "isodoc/terms"
require_relative "isodoc/blocks"
require_relative "isodoc/lists"
require_relative "isodoc/table"
require_relative "isodoc/inline"
require_relative "isodoc/xref_gen"
require_relative "isodoc/html"
require "pp"

module IsoDoc
  class Convert

    # htmlstylesheet: Generic stylesheet for HTML
    # wordstylesheet: Generic stylesheet for Word
    # standardsheet: Stylesheet specific to Standard
    # header: Header file for Word
    # htmlcoverpage: Cover page for HTML
    # wordcoverpage: Cover page for Word
    # htmlintropage: Introductory page for HTML
    # wordintropage: Introductory page for Word
    def initialize(options)
      @htmlstylesheet = options[:htmlstylesheet]
      @wordstylesheet = options[:wordstylesheet]
      @standardstylesheet = options[:standardstylesheet]
      @header = options[:header]
      @htmlcoverpage = options[:htmlcoverpage]
      @wordcoverpage = options[:wordcoverpage]
      @htmlintropage = options[:htmlintropage]
      @wordintropage = options[:wordintropage]
      @termdomain = ""
      @termexample = false
      @note = false
      @sourcecode = false
      @anchors = {}
      @meta = {}
      @footnotes = []
      @comments = []
      @in_footnote = false
    end

    def convert(filename)
      docxml = Nokogiri::XML(File.read(filename))
      filename, dir = init_file(filename)
      docxml.root.default_namespace = ""
      result = noko do |xml|
        xml.html do |html|
          html_header(html, docxml, filename, dir)
          make_body(html, docxml)
        end
      end.join("\n")
      postprocess(result, filename, dir)
    end
  end
end
