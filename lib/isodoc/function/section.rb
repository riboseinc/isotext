module IsoDoc::Function
  module Section
    def inline_header_title(out, node, c1)
      title = c1&.content || ""
      out.span **{ class: "zzMoveToFollowing" } do |s|
        s.b do |b|
          if get_anchors[node['id']][:label]
            b << "#{get_anchors[node['id']][:label]}. " unless @suppressheadingnumbers
          end
          b << "#{title} "
        end
      end
    end

    def clause_parse_title(node, div, c1, out)
      if node["inline-header"] == "true"
        inline_header_title(out, node, c1)
      else
        div.send "h#{get_anchors[node['id']][:level]}" do |h|
          lbl = get_anchors[node['id']][:label]
          h << "#{lbl}. " if lbl && !@suppressheadingnumbers
          c1&.children&.each { |c2| parse(c2, h) }
        end
      end
    end

    def clause_parse(node, out)
      out.div **attr_code(id: node["id"]) do |div|
        clause_parse_title(node, div, node.at(ns("./title")), out)
        node.children.reject { |c1| c1.name == "title" }.each do |c1|
          parse(c1, div)
        end
      end
    end

    def clause_name(num, title, div, header_class)
      header_class = {} if header_class.nil?
      div.h1 **attr_code(header_class) do |h1|
        if num && !@suppressheadingnumbers
          h1 << "#{num}."
          insert_tab(h1, 1)
        end
        h1 << title
      end
      div.parent.at(".//h1")
    end

    MIDDLE_CLAUSE =
      "//clause[parent::sections][not(xmlns:title = 'Scope')]"\
      "[not(descendant::terms)]".freeze

    def clause(isoxml, out)
      isoxml.xpath(ns(self.class::MIDDLE_CLAUSE)).each do |c|
        out.div **attr_code(id: c["id"]) do |s|
          clause_name(get_anchors[c['id']][:label],
                      c&.at(ns("./title"))&.content, s, nil)
          c.elements.reject { |c1| c1.name == "title" }.each do |c1|
            parse(c1, s)
          end
        end
      end
    end

    def annex_name(annex, name, div)
      div.h1 **{ class: "Annex" } do |t|
        t << "#{get_anchors[annex['id']][:label]}<br/><br/>"
        t.b do |b|
          name&.children&.each { |c2| parse(c2, b) }
        end
      end
    end

    def annex(isoxml, out)
      isoxml.xpath(ns("//annex")).each do |c|
        page_break(out)
        out.div **attr_code(id: c["id"], class: "Section3") do |s|
          c.elements.each do |c1|
            if c1.name == "title" then annex_name(c, c1, s)
            else
              parse(c1, s)
            end
          end
        end
      end
    end

    def scope(isoxml, out, num)
      f = isoxml.at(ns("//clause[title = 'Scope']")) or return num
      out.div **attr_code(id: f["id"]) do |div|
        num = num + 1
        clause_name(num, @scope_lbl, div, nil)
        f.elements.each do |e|
          parse(e, div) unless e.name == "title"
        end
      end
      num
    end

    def external_terms_boilerplate(sources)
      @external_terms_boilerplate.gsub(/%/, sources || "???")
    end

    def internal_external_terms_boilerplate(sources)
      @internal_external_terms_boilerplate.gsub(/%/, sources || "??")
    end

    def term_defs_boilerplate(div, source, term, preface)
      source.each { |s| @anchors[s["bibitemid"]] or warn "#{s['bibitemid']} not referenced" }
      if source.empty? && term.nil?
        div << @no_terms_boilerplate
      else
        div << term_defs_boilerplate_cont(source, term)
      end
      div << @term_def_boilerplate
    end

    def term_defs_boilerplate_cont(src, term)
      sources = sentence_join(src.map { |s| @anchors.dig(s["bibitemid"], :xref) })
      if src.empty? then @internal_terms_boilerplate
      elsif term.nil? then external_terms_boilerplate(sources)
      else
        internal_external_terms_boilerplate(sources)
      end
    end

    def terms_defs_title(f)
      symbols = f.at(ns(".//definitions"))
      return @termsdefsymbols_lbl if symbols
      @termsdef_lbl
    end

    TERM_CLAUSE = "//sections/terms | "\
      "//sections/clause[descendant::terms]".freeze

    def terms_defs(isoxml, out, num)
      f = isoxml.at(ns(TERM_CLAUSE)) or return num
      out.div **attr_code(id: f["id"]) do |div|
        num = num + 1
        clause_name(num, terms_defs_title(f), div, nil)
        term_defs_boilerplate(div, isoxml.xpath(ns(".//termdocsource")),
                              f.at(ns(".//term")), f.at(ns("./p")))
        f.elements.each do |e|
          parse(e, div) unless %w{title source}.include? e.name
        end
      end
      num
    end

    # subclause
    def terms_parse(isoxml, out)
      clause_parse(isoxml, out)
    end

    def symbols_abbrevs(isoxml, out, num)
      f = isoxml.at(ns("//sections/definitions")) or return num
      out.div **attr_code(id: f["id"], class: "Symbols") do |div|
        num = num + 1
        clause_name(num, @symbols_lbl, div, nil)
        f.elements.each do |e|
          parse(e, div) unless e.name == "title"
        end
      end
      num
    end

    # subclause
    def symbols_parse(isoxml, out)
      isoxml.children.first.previous =
        "<title>#{@symbols_lbl}</title>"
      clause_parse(isoxml, out)
    end

    def introduction(isoxml, out)
      f = isoxml.at(ns("//introduction")) || return
      title_attr = { class: "IntroTitle" }
      page_break(out)
      out.div **{ class: "Section3", id: f["id"] } do |div|
        clause_name(nil, @introduction_lbl, div, title_attr)
        f.elements.each do |e|
          parse(e, div) unless e.name == "title"
        end
      end
    end

    def foreword(isoxml, out)
      f = isoxml.at(ns("//foreword")) || return
      page_break(out)
      out.div **attr_code(id: f["id"]) do |s|
        s.h1(**{ class: "ForewordTitle" }) { |h1| h1 << @foreword_lbl }
        f.elements.each { |e| parse(e, s) unless e.name == "title" }
      end
    end
  end
end
