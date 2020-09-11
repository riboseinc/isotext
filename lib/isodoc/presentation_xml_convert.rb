require_relative "presentation_function/block"
require_relative "presentation_function/inline"
require_relative "presentation_function/section"

module IsoDoc
  class PresentationXMLConvert < ::IsoDoc::Convert
    def initialize(options)
      @format = :presentation
      @suffix = "presentation.xml"
      super
    end

    def convert1(docxml, filename, dir)
      @xrefs.parse docxml
      info docxml, nil
      conversions(docxml)
      docxml.to_xml
    end

    def conversions(docxml)
      section docxml
      block docxml
      inline docxml
    end

    def section(docxml)
      clause docxml
      annex docxml
      term docxml
    end

    def block(docxml)
      amend docxml
      table docxml
      figure docxml
      sourcecode docxml
      formula docxml
      example docxml
      termexample docxml
      note docxml
      termnote docxml
      permission docxml
      requirement docxml
      recommendation docxml
    end

    def inline(docxml)
      xref docxml
      eref docxml
      origin docxml
      quotesource docxml
    end

    def postprocess(result, filename, dir)
      toXML(result, filename)
      @files_to_delete.each { |f| FileUtils.rm_rf f }
    end

    def toXML(result, filename)
      File.open(filename, "w:UTF-8") { |f| f.write(result) }
    end
  end
end
