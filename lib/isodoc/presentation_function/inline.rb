module IsoDoc
  class PresentationXMLConvert < ::IsoDoc::Convert
    def prefix_container(container, linkend, _target)
      l10n(@xrefs.anchor(container, :xref) + ", " + linkend)
    end

    def anchor_linkend(node, linkend)
      if node["citeas"].nil? && node["bibitemid"]
        return @xrefs.anchor(node["bibitemid"] ,:xref) || "???"
      elsif node["target"] && !/.#./.match(node["target"])
        linkend = @xrefs.anchor(node["target"], :xref)
        container = @xrefs.anchor(node["target"], :container, false)
        (container && get_note_container_id(node) != container &&
         @xrefs.get[node["target"]]) &&
        linkend = prefix_container(container, linkend, node["target"])
        linkend = capitalise_xref(node, linkend)
      end
      linkend || "???"
    end

    def capitalise_xref(node, linkend)
      return linkend unless %w(Latn Cyrl Grek).include? @script
      return linkend&.capitalize if node["case"] == "capital"
      return linkend&.downcase if node["case"] == "lowercase"
      return linkend if linkend[0,1].match(/\p{Upper}/)
      prec = nearest_block_parent(node).xpath("./descendant-or-self::text()") &
        node.xpath("./preceding::text()")
      (prec.empty? || /(?!<[^.].)\.\s+$/.match(prec.map { |p| p.text }.join)) ?
        linkend&.capitalize : linkend
    end

    def nearest_block_parent(node)
      until %w(p title td th name formula 
        li dt dd sourcecode pre).include?(node.name)
        node = node.parent
      end
      node
    end

    def get_linkend(node)
      contents = node.children.select do |c|
        !%w{locality localityStack}.include? c.name
      end.select { |c| !c.text? || /\S/.match(c) }
      return unless contents.empty?
      link = anchor_linkend(node, docid_l10n(node["target"] || node["citeas"]))
      link += eref_localities(node.xpath(ns("./locality | ./localityStack")), link)
      node.children.select do |c|
        !%w{locality localityStack}.include? c.name
      end.each { |n| n.remove }
      node.add_child(link)
    end
    # so not <origin bibitemid="ISO7301" citeas="ISO 7301">
    # <locality type="section"><reference>3.1</reference></locality></origin>

    def eref_localities(refs, target)
      ret = ""
      refs.each_with_index do |r, i|
        delim = ","
        delim = ";" if r.name == "localityStack" && i>0
        if r.name == "localityStack"
          r.elements.each_with_index do |rr, j|
            ret += eref_localities0(rr, j, target, delim)
            delim = ","
          end
        else
          ret += eref_localities0(r, i, target, delim)
        end
      end
      ret
    end

    def eref_localities0(r, i, target, delim)
      if r["type"] == "whole" then l10n("#{delim} #{@wholeoftext_lbl}")
      else
        eref_localities1(target, r["type"], r.at(ns("./referenceFrom")),
                         r.at(ns("./referenceTo")), delim, @lang)
      end
    end

     # TODO: move to localization file
    def eref_localities1_zh(target, type, from, to, delim)
      ret = "#{delim} 第#{from.text}" if from
      ret += "&ndash;#{to.text}" if to
      loc = (@locality[type] || type.sub(/^locality:/, "").capitalize )
      ret += " #{loc}"
      ret
    end

    # TODO: move to localization file
    def eref_localities1(target, type, from, to, delim, lang = "en")
      return "" if type == "anchor"
      return l10n(eref_localities1_zh(target, type, from, to, delim)) if lang == "zh"
      ret = delim
      loc = @locality[type] || type.sub(/^locality:/, "").capitalize
      ret += " #{loc}"
      ret += " #{from.text}" if from
      ret += "&ndash;#{to.text}" if to
      l10n(ret)
    end

    def xref(docxml)
      docxml.xpath(ns("//xref")).each do |f|
        xref1(f)
      end
    end

    def eref(docxml)
      docxml.xpath(ns("//eref")).each do |f|
        xref1(f)
      end
    end

    def origin(docxml)
      docxml.xpath(ns("//origin[not(termref)]")).each do |f|
        xref1(f)
      end
    end

    def quotesource(docxml)
      docxml.xpath(ns("//quote/source")).each do |f|
        xref1(f)
      end
    end

    def xref1(f)
      get_linkend(f)
    end
  end
end
