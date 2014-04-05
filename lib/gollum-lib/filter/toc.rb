# Inserts header anchors and creates TOC
class Gollum::Filter::TOC < Gollum::Filter
  def extract(d)
    d
  end

  def process(data)
    doc          = Nokogiri::HTML::DocumentFragment.parse(data)
    toc          = nil
    anchor_names = {}

    doc.css('h1,h2,h3,h4,h5,h6').each do |h|
      # must escape "
      h_name               = h.content.gsub(' ', '-').gsub('"', '%22')

      # Ensure repeat anchors have a unique prefix or the
      # toc will break
      anchor_names[h_name] = 0 if anchor_names[h_name].nil?
      anchor_names[h_name] += 1

      anchor_prefix_number = anchor_names[h_name]
      if anchor_prefix_number > 1
        h_name = anchor_prefix_number.to_s + '-' + h_name
      end

      level = h.name.gsub(/[hH]/, '').to_i

      # Add anchors
      anchor_element = %Q(<a class="anchor" id="#{h_name}" href="##{h_name}"><i class="fa fa-link"></i></a>)
      # Add anchor element as the first child (before h.content)
      h.children.before anchor_element

      # Build TOC
      toc        ||= Nokogiri::XML::DocumentFragment.parse('<div class="toc"><div class="toc-title">Table of Contents</div></div>')
      tail       ||= toc.child
      tail_level ||= 0

      while tail_level < level
        node       = Nokogiri::XML::Node.new('ul', doc)
        tail       = tail.add_child(node)
        tail_level += 1
      end
      while tail_level > level
        tail       = tail.parent
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