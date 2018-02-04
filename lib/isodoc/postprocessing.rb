require "html2doc"
require "htmlentities"
require "nokogiri"
require "pp"

module IsoDoc
  class Convert

    def postprocess(result, filename, dir)
      generate_header(filename, dir)
      result = cleanup(Nokogiri::HTML(result)).to_xml
      toWord(result, filename, dir)
      toHTML(result, filename)
    end

    def toWord(result, filename, dir)
      result = wordPreface(Nokogiri::HTML(result)).to_xml
      result = populate_template(result)
      Html2Doc.process(result, filename, @wordstylesheet, "header.html", 
                       dir, ['`', '`'])
    end

    def wordPreface(docxml)
      cover = Nokogiri::HTML(File.read(@wordcoverpage, encoding: "UTF-8"))
      d = docxml.at('//div[@class="WordSection1"]')
      d.children.first.add_previous_sibling cover.to_xml(encoding: 'US-ASCII')
      intro = Nokogiri::HTML(File.read(@wordintropage, encoding: "UTF-8"))
      d = docxml.at('//div[@class="WordSection2"]')
      d.children.first.add_previous_sibling intro.to_xml(encoding: 'US-ASCII')
      docxml
    end

    def cleanup(docxml)
      comment_cleanup(docxml)
      footnote_cleanup(docxml)
      docxml
    end

    def comment_cleanup(docxml)
      docxml.xpath('//div/span[@style="MsoCommentReference"]').
        each do |x|
        prev = x.previous_element
        if !prev.nil?
          x.parent = prev
        end
      end
      docxml
    end

    def footnote_cleanup(docxml)
      docxml.xpath('//div[@style="mso-element:footnote"]/a').
        each do |x|
        n = x.next_element
        if !n.nil?
          n.children.first.add_previous_sibling(x.remove)
        end
      end
      docxml
    end

    def populate_template(docxml)
      meta = get_metadata
      docxml.
        gsub(/DOCYEAR/, meta[:docyear]).
        gsub(/DOCNUMBER/, meta[:docnumber]).
        gsub(/TCNUM/, meta[:tc]).
        gsub(/SCNUM/, meta[:sc]).
        gsub(/WGNUM/, meta[:wg]).
        gsub(/DOCTITLE/, meta[:doctitle]).
        gsub(/DOCSUBTITLE/, meta[:docsubtitle]).
        gsub(/SECRETARIAT/, meta[:secretariat]).
        gsub(/\[TERMREF\]\s*/, "[SOURCE: ").
        gsub(/\s*\[\/TERMREF\]\s*/, "]").
        gsub(/\s*\[ISOSECTION\]/, ", ").
        gsub(/\s*\[MODIFICATION\]/, ", modified &mdash; ").
        gsub(%r{WD/CD/DIS/FDIS}, meta[:stageabbr])
    end

    def generate_header(filename, dir)
      header = File.read(@header, encoding: "UTF-8").
        gsub(/FILENAME/, filename).
        gsub(/DOCYEAR/, get_metadata()[:docyear]).
        gsub(/DOCNUMBER/, get_metadata()[:docnumber])
      File.open("header.html", "w") do |f|
        f.write(header)
      end
    end

    # these are in fact preprocess,
    # but they are extraneous to main HTML file
    def html_header(html, docxml, filename, dir)
      anchor_names docxml
      define_head html, filename, dir
    end

    # isodoc.css overrides any CSS injected by Html2Doc, which
    # is inserted before this CSS.
    def define_head(html, filename, dir)
      html.head do |head|
        head.title { |t| t << filename }
        head.style do |style|
          stylesheet = File.read(@standardstylesheet).
            gsub("FILENAME", filename)
          style.comment "\n#{stylesheet}\n"
        end
      end
    end

    def titlepage(_docxml, div)
      titlepage = File.read(@wordcoverpage, encoding: "UTF-8")
      div.parent.add_child titlepage
    end
  end
end
