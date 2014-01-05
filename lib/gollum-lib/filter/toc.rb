# Inserts header anchors and creates TOC
class Gollum::Filter::TOC < Gollum::Filter
  def extract(d) d; end
  
  def process(data)
    doc = Nokogiri::HTML::DocumentFragment.parse(data)
    toc = nil
    doc.css('h1,h2,h3,h4,h5,h6').each do |h|
      # must escape "
      h_name = h.content.gsub(' ','-').gsub('"','%22')

      level = h.name.gsub(/[hH]/,'').to_i

      # Add anchors
      h.add_child(%Q{<a class="anchor" id="#{h_name}" href="##{h_name}"></a>})

      # Build TOC
      toc ||= Nokogiri::XML::DocumentFragment.parse('<div class="toc"><div class="toc-title">Table of Contents</div></div>')
      tail ||= toc.child
      tail_level ||= 0

      while tail_level < level
        node = Nokogiri::XML::Node.new('ul', doc)
        tail = tail.add_child(node)
        tail_level += 1
      end
      while tail_level > level
        tail = tail.parent
        tail_level -= 1
      end
      node = Nokogiri::XML::Node.new('li', doc)
      # % -> %25 so anchors work on Firefox. See issue #475
      node.add_child(%Q{<a href="##{h_name}">#{h.content}</a>})
      tail.add_child(node)
    end

    toc  = toc.to_xml(@markup.to_xml_opts) if toc != nil
    data = doc.to_xml(@markup.to_xml_opts)

    @markup.toc = toc
    data.gsub("[[_TOC_]]") do
      toc.nil? ? '' : toc
    end
  end
end
