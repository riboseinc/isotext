require "html2doc"
require "htmlentities"
require "nokogiri"
require "pp"

module IsoDoc
  class Convert
    def cleanup(docxml)
      comment_cleanup(docxml)
      footnote_cleanup(docxml)
      inline_header_cleanup(docxml)
      figure_cleanup(docxml)
      table_cleanup(docxml)
      docxml
    end

    def figure_get_or_make_dl(t)
      dl = t.at(".//dl")
      if dl.nil?
        t.add_child("<p><b>Key</b></p><dl></dl>")
        dl = t.at(".//dl")
      end
      dl
    end

    FIGURE_WITH_FOOTNOTES =
      "//div[@class = 'figure'][descendant::aside]"\
      "[not(descendant::div[@class = 'figure'])]".freeze

    def figure_aside_process(f, aside, key)
      # get rid of footnote link, it is in diagram
      f.at("./a[@class='zzFootnote']").remove
      fnref = f.at(".//a[@class='zzFootnote']")
      dt = key.add_child("<dt></dt>").first
      dd = key.add_child("<dd></dd>").first
      fnref.parent = dt
      aside.xpath(".//p").each do |a| 
        a.delete("class")
        a.parent = dd 
      end
    end

    def figure_cleanup(docxml)
      # move footnotes into key, and get rid of footnote reference 
      # since it is in diagram
      docxml.xpath(FIGURE_WITH_FOOTNOTES).each do |f|
        key = figure_get_or_make_dl(f)
        f.xpath(".//aside").each do |aside|
          figure_aside_process(f, aside, key)
        end
      end
    end

    def inline_header_cleanup(docxml)
      docxml.xpath('//span[@class="zzMoveToFollowing"]').each do |x|
        n = x.next_element
        if n.nil?
          html = Nokogiri::XML.fragment("<p></p>")
          html.parent = x.parent
          x.parent = html
        else
          n.children.first.add_previous_sibling(x.remove)
        end
      end
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

    def merge_fnref_into_fn_text(a)
      fn = a.at('.//a[@class="zzFootnote"]')
      n = fn.next_element
      n.children.first.add_previous_sibling(fn.remove) unless n.nil?
    end

    TABLE_WITH_FOOTNOTES = "//table[descendant::aside]".freeze

    def table_footnote_cleanup(docxml)
      docxml.xpath(TABLE_WITH_FOOTNOTES).each do |t|
        t.xpath(".//aside").each do |a|
          merge_fnref_into_fn_text(a)
          a.name = "div"
          a["class"] = "Note"
          t << a.remove
        end
      end
    end

    def remove_bottom_border(td)
      td["style"] =
        td["style"].gsub(/border-bottom:[^;]+;/, "border-bottom:0pt;").
        gsub(/mso-border-bottom-alt:[^;]+;/, "mso-border-bottom-alt:0pt;")
    end

    def table_get_or_make_tfoot(t)
      tfoot = t.at(".//tfoot")
      if tfoot.nil?
        t.add_child("<tfoot></tfoot>")
        tfoot = t.at(".//tfoot")
      else
        # nuke its bottom border
        tfoot.xpath(".//td | .//th").each do |td|
          remove_bottom_border(td)
        end
      end
      tfoot
    end

    def new_fullcolspan_row(t, tfoot)
      # how many columns in the table?
      cols = 0
      t.at(".//tr").xpath("./td | ./th").each do |td|
        cols += ( td["colspan"] ? td["colspan"].to_i : 1 )
      end
      style = %{border-top:0pt;mso-border-top-alt:0pt;
      border-bottom:#{SW} 1.5pt;mso-border-bottom-alt:#{SW} 1.5pt;}
      tfoot.add_child("<tr><td colspan='#{cols}' style='#{style}'/></tr>")
      tfoot.xpath(".//td").last
    end

    def table_note_cleanup(docxml)
      docxml.xpath("//table[div[@class = 'Note']]").each do |t|
        tfoot = table_get_or_make_tfoot(t)
        insert_here = new_fullcolspan_row(t, tfoot)
        t.xpath("div[@class = 'Note']").each do |d|
          d.parent = insert_here
        end
      end
    end

    def table_cleanup(docxml)
      table_footnote_cleanup(docxml)
      table_note_cleanup(docxml)
    end
  end
end