module IsoDoc::Function
  module Lists
    def ul_attrs(node)
      { id: node["id"], style: keep_style(node) }
    end

    def ul_parse(node, out)
      out.ul **attr_code(ul_attrs(node)) do |ul|
        node.children.each { |n| parse(n, ul) }
      end
    end

    OL_STYLE = {
      arabic: "1",
      roman: "i",
      alphabet: "a",
      roman_upper: "I",
      alphabet_upper: "A",
    }.freeze

    def ol_style(type)
      type = :alphabet unless type
      OL_STYLE[type.to_sym]
    end

    # We don't really want users to specify type of ordered list;
    # we will use a fixed hierarchy as practiced by ISO (though not
    # fully spelled out): a) 1) i) A) I)

    def ol_depth(node)
      depth = node.ancestors("ul, ol").size + 1
      type = :alphabet
      type = :arabic if [2, 7].include? depth
      type = :roman if [3, 8].include? depth
      type = :alphabet_upper if [4, 9].include? depth
      type = :roman_upper if [5, 10].include? depth
      ol_style(type)
    end

    def ol_attrs(node)
      { type: node["type"] ? ol_style(node["type"].to_sym) : ol_depth(node),
        id: node["id"], style: keep_style(node) }
    end

    def ol_parse(node, out)
      out.ol **attr_code(ol_attrs(node)) do |ol|
        node.children.each { |n| parse(n, ol) }
      end
    end

    def li_parse(node, out)
      out.li  **attr_code(id: node["id"]) do |li|
        if node["uncheckedcheckbox"] == "true"
          li << '<span class="zzMoveToFollowing"><input type="checkbox" checked="checked"/></span>'
        elsif node["checkedcheckbox"] == "true"
          li << '<span class="zzMoveToFollowing"><input type="checkbox"/></span>'
        end
        node.children.each { |n| parse(n, li) }
      end
    end

    def dt_parse(dt, term)
      if dt.elements.empty?
        #term.p **attr_code(class: note? ? "Note" : nil) do |p|
        term.p do |p|
          p << dt.text
        end
      else
        dt.children.each { |n| parse(n, term) }
      end
    end

    def dt_dd?(n)
      %w{dt dd}.include? n.name
    end

    def dl_attrs(node)
      attr_code(id: node["id"], style: keep_style(node))
    end

    def dl_parse(node, out)
      out.dl  **dl_attrs(node) do |v|
        node.elements.select { |n| dt_dd? n }.each_slice(2) do |dt, dd|
          v.dt **attr_code(id: dt["id"]) do |term|
            dt_parse(dt, term) 
          end
          v.dd  **attr_code(id: dd["id"]) do |listitem|
            dd.children.each { |n| parse(n, listitem) }
          end
        end
      end
      node.elements.reject { |n| dt_dd? n }.each { |n| parse(n, out) }
    end
  end
end
