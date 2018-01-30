require "uuidtools"
require "html2doc"
#require_relative "./xref_gen"

module IsoDoc
  #module Postprocessing
    #include ::IsoDoc::XrefGen

    def self.postprocess(result, filename, dir)
      generate_header(filename, dir)
      result = cleanup(Nokogiri::XML(result)).to_xml
      result = populate_template(result)
      File.open("#{filename}.out.html", "w") do |f|
        f.write(result)
      end
      Html2Doc.process(result, filename, "header.html", dir)
    end

    def self.cleanup(docxml)
      comment_cleanup(docxml)
      footnote_cleanup(docxml)
      docxml
    end

    def self.comment_cleanup(docxml)
      docxml.xpath('//div/span[@style="MsoCommentReference"]').
        each do |x|
        prev = x.previous_element
        if !prev.nil?
          x.parent = prev
        end
      end
      docxml
    end

    def self.footnote_cleanup(docxml)
      docxml.xpath('//div[@style="mso-element:footnote"]/a').
        each do |x|
        n = x.next_element
        if !n.nil?
          n.children.first.add_previous_sibling(x.remove)
        end
      end
      docxml
    end

    def self.populate_template(docxml)
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

    def self.generate_header(filename, dir)
      hdr_file = File.join(File.dirname(__FILE__), "header.html")
      header = File.read(hdr_file, encoding: "UTF-8").
        gsub(/FILENAME/, filename).
        gsub(/DOCYEAR/, get_metadata()[:docyear]).
        gsub(/DOCNUMBER/, get_metadata()[:docnumber])
      File.open("header.html", "w") do |f|
        f.write(header)
      end
    end

    # these are in fact preprocess,
    # but they are extraneous to main HTML file
    def self.html_header(html, docxml, filename, dir)
      anchor_names docxml
      define_head html, filename, dir
    end

    # isodoc.css overrides any CSS injected by Html2Doc, which
    # is inserted before this CSS.
    def self.define_head(html, filename, dir)
      html.head do |head|
        head.title { |t| t << filename }
        head.style do |style|
          fn = File.join(File.dirname(__FILE__), "isodoc.css")
          stylesheet = File.read(fn).gsub("FILENAME", filename)
          style.comment "\n#{stylesheet}\n"
        end
      end
    end

    def self.titlepage(_docxml, div)
      fn = File.join(File.dirname(__FILE__), "iso_titlepage.html")
      titlepage = File.read(fn, encoding: "UTF-8")
      div.parent.add_child titlepage
    end
  end
#end
