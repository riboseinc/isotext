module IsoDoc
  #module Inline

    @@footnotes = []
    @@comments = []
    @@xslt = XML::XSLT.new
    @@xslt.xsl = File.read(File.join(File.dirname(__FILE__),
                                     "mathml2omml.xsl"))
    @@in_footnote = false

    def self.in_footnote
      @@in_footnote
    end

    def self.section_break(body)
      body.br **{ clear: "all", class: "section" }
    end

    def self.page_break(body)
      body.br **{ 
        clear: "all",
        style: "mso-special-character:line-break;page-break-before:always",
      }
    end

    def self.link_parse(node, out)
      linktext = node.text
      linktext = node["target"] if linktext.empty?
      out.a **{ "href": node["target"] } { |l| l << linktext }
    end

    def self.callout_parse(node, out)
      out << " &lt;#{node.text}&gt;"
    end

    def self.get_linkend(node)
      linkend = node["target"] || node["citeas"]
      if get_anchors().has_key? node["target"]
        linkend = get_anchors()[node["target"]][:xref]
      end
      if node["citeas"].nil? && get_anchors().has_key?(node["bibitemid"])
        linkend = get_anchors()[node["bibitemid"]][:xref]
      end
      text = node.children.select { |c| c.text? && !c.text.empty? }
      linkend = text.join(" ") unless text.nil? || text.empty?
      # so not <origin bibitemid="ISO7301" citeas="ISO 7301">
      # <locality type="section">3.1</locality></origin>
      linkend
    end

    def self.xref_parse(node, out)
      linkend = get_linkend(node)
      out.a **{ "href": node["target"] } { |l| l << linkend }
    end

    def self.eref_parse(node, out)
      linkend = get_linkend(node)
      section = node.at(ns("./locality"))
      section.nil? or
        linkend += ", #{section["type"].capitalize} #{section.text}"
      if node["type"] == "footnote"
        out.sup do |s|
          s.a **{ "href": node["bibitemid"] } { |l| l << linkend }
        end
      else
        out.a **{ "href": node["bibitemid"] } { |l| l << linkend }
      end
    end

    def self.stem_parse(node, out)
      @@xslt.xml = AsciiMath.parse(node.text).to_mathml.
        gsub(/<math>/,
             "<math xmlns='http://www.w3.org/1998/Math/MathML'>")
      ooml = @@xslt.serve.gsub(/<\?[^>]+>\s*/, "").
        gsub(/ xmlns:[^=]+="[^"]+"/, "")
      out.span **{ class: "stem" } do |span|
        span.parent.add_child ooml
      end
    end

    def self.pagebreak_parse(node, out)
      attrs = { clear: all, class: "pagebreak" }
      out.br **attrs
    end

    def self.error_parse(node, out)
      text = node.to_xml.gsub(/</, "&lt;").gsub(/>/, "&gt;")
      out.para do |p|
        p.b **{ role: "strong" } { |e| e << text }
      end
    end

    def self.footnotes(div)
      return if @@footnotes.empty?
      div.div **{ style: "mso-element:footnote-list" } do |div1|
        @@footnotes.each do |fn|
          div1.parent << fn
        end
      end
    end

    def self.footnote_attributes(fn)
      {
        style: "mso-footnote-id:ftn#{fn}",
        href: "#_ftn#{fn}",
        name: "_ftnref#{fn}",
        title: "",
      }
    end

    def self.make_footnote_link(a)
      a.span **{ class: "MsoFootnoteReference" } do |s|
        s.span **{ style: "mso-special-character:footnote" }
      end
    end

    def self.make_footnote_text(node, fn)
      noko do |xml|
        xml.div **{ style: "mso-element:footnote", id: "ftn#{fn}" } do |div|
          div.a **footnote_attributes(fn) do |a|
            make_footnote_link(a)
          end
          node.children.each { |n| parse(n, div) }
        end
      end.join("\n")
    end

    def self.footnote_parse(node, out)
      fn = node["reference"]
      out.a **footnote_attributes(fn) do |a| 
        make_footnote_link(a) 
      end
      @@in_footnote = true
      @@footnotes << make_footnote_text(node, fn)
      @@in_footnote = false
    end

    def self.comments(div)
      return if @@comments.empty?
      div.div **{ style: "mso-element:comment-list" } do |div1|
        @@comments.each do |fn|
          div1.parent << fn
        end
      end
    end

    def self.make_comment_link(out, fn, date, from)
      out.span **{ style: "MsoCommentReference" } do |s1|
        s1.span **{ lang: "EN-GB", style: "font-size:9.0pt"} do |s2|
          s2.a **{ style: "mso-comment-reference:SMC_#{fn};"\
                   "mso-comment-date:#{date}" } if from
          s2.span **{ style: "mso-special-character:comment" } do |s|
            s << "&nbsp;"
          end
        end
      end
    end

    def self.make_comment_text(node, fn)
      noko do |xml|
        xml.div **{ style: "mso-element:comment" } do |div|
          div.span **{ style: %{mso-comment-author:"#{node["reviewer"]}"} }
          div.p **{ class: "MsoCommentText" } do |p|
            make_comment_link(p, fn, node["date"], false)
            node.children.each { |n| parse(n, p) }
          end
        end
      end.join("\n")
    end

    def self.review_note_parse(node, out)
      fn = @@comments.length + 1
      make_comment_link(out, fn, node["date"], true)
      @@comments << make_comment_text(node, fn)
    end
  end
#end
