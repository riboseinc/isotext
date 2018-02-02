module IsoDoc
  class Convert

    def toHTML(result, filename)
      result = htmlstyle(Nokogiri::HTML(result)).to_xml
      File.open("#{filename}.html", "w") do |f|
        f.write(result)
      end
    end

    def htmlstylesheet
      stylesheet = File.read(@htmlstylesheet, encoding: "UTF-8")
      xml = Nokogiri::XML("<style/>")
      xml.children.first << Nokogiri::XML::Comment.new(xml, "\n#{stylesheet}\n")
      xml.root.to_s
    end


    def htmlstyle(docxml)
      title = docxml.at("//*[local-name() = 'head']/*[local-name() = 'title']")
      head = docxml.at("//*[local-name() = 'head']")
      css = htmlstylesheet
      if title.nil?
        head.children.first.add_previous_sibling css
      else
        title.add_next_sibling css
      end
      docxml
    end
  end
end