# Inserts header anchors and creates TOC
class Gollum::Filter::TOC < Gollum::Filter
  def extract(data)
    data
  end

  def process(data)

    @doc               = Nokogiri::HTML::DocumentFragment.parse(data)
    @toc_doc           = nil
    @anchor_names      = {}
    @current_ancestors = []

    toc_str            = ''
    if @markup.sub_page && @markup.parent_page
      toc_str = @markup.parent_page.toc_data
    else
      @doc.css('h1,h2,h3,h4,h5,h6').each_with_index do |header, i|
        next if header.content.empty?
        # omit the first H1 (the page title) from the TOC if so configured
        next if (i == 0 && header.name =~ /[Hh]1/) && @markup.wiki && @markup.wiki.h1_title

        anchor_name = generate_anchor_name(header)
        
        add_anchor_to_header header, anchor_name
        add_entry_to_toc     header, anchor_name
      end
      if not @toc_doc.nil?
        toc_str = @toc_doc.to_xml(@markup.to_xml_opts)
      end

      data  = @doc.to_xml(@markup.to_xml_opts)
    end

    @markup.toc = toc_str

    data.gsub!(/\[\[_TOC_(.*?)\]\]/) do
      levels = nil
      levels_match = Regexp.last_match[1].match /\|\s*levels\s*=\s*(\d+)/
      if levels_match
        levels = levels_match[1].to_i
      end

      if levels.nil? || toc_str.empty?
        toc_str
      else
        @toc_doc ||= Nokogiri::HTML::DocumentFragment.parse(toc_str)
        toc_clone = @toc_doc.clone
        toc_clone.traverse do |e|
          if e.name == 'ul' and e.ancestors.length > levels + 1
            e.remove
          end
        end
        toc_clone.to_xml(@markup.to_xml_opts)
      end
    end

    data
  end

  private

  # Generates the anchor name from the given header element 
  # removing all non alphanumeric characters, replacing them
  # with single dashes.  
  #
  # Generates heading ancestry prefixing the headings
  # ancestor names to the generated name.
  #
  # Prefixes duplicate anchors with an index
  def generate_anchor_name(header)
    name = header.content
    level = header.name.gsub(/[hH]/, '').to_i

    # normalize the header name
    name.gsub!(/[^\d\w\u00C0-\u1FFF\u2C00-\uD7FF]/, "-")
    name.gsub!(/-+/, "-")
    name.gsub!(/^-/, "")
    name.gsub!(/-$/, "")
    name.downcase!

    @current_ancestors[level - 1] = name
    @current_ancestors = @current_ancestors.take(level)
    anchor_name = @current_ancestors.compact.join("_")

    # Ensure duplicate anchors have a unique prefix or the toc will break
    index = increment_anchor_index(anchor_name)
    anchor_name = "#{index}-#{anchor_name}" unless index.zero? # if the index is zero this name is unique

    anchor_name
  end

  # Creates an anchor element with the given name and adds it before
  # the given header element.
  def add_anchor_to_header(header, name)
    anchor_element = %Q(<a class="anchor" id="#{name}" href="##{name}"><i class="fa fa-link"></i></a>)
    header.children.before anchor_element # Add anchor element before the header
  end

  # Adds an entry to the TOC for the given header.  The generated entry
  # is a link to the given anchor name
  def add_entry_to_toc(header, name)
    @toc_doc ||= Nokogiri::XML::DocumentFragment.parse('<div class="toc"><div class="toc-title">Table of Contents</div></div>')
    tail ||= @toc_doc.child
    tail_level ||= 0

    level = header.name.gsub(/[hH]/, '').to_i

    while tail_level < level
      node = Nokogiri::XML::Node.new('ul', @doc)
      tail = tail.add_child(node)
      tail_level += 1
    end
    
    while tail_level > level
      tail = tail.parent
      tail_level -= 1
    end
    node = Nokogiri::XML::Node.new('li', @doc)
    # % -> %25 so anchors work on Firefox. See issue #475
    node.add_child(%Q{<a href="##{name}">#{header.content}</a>})
    tail.add_child(node)
  end

  # Increments the number of anchors with the given name
  # and returns the current index
  def increment_anchor_index(name)
    @anchor_names = {} if @anchor_names.nil?
    @anchor_names[name].nil? ? @anchor_names[name] = 0 : @anchor_names[name] += 1
  end
end
