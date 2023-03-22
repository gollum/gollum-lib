# Inserts header anchors and creates TOC
class Gollum::Filter::TOC < Gollum::Filter

  HEADERS = (1..6).to_a

  def extract(data)
    data
  end

  def process(data)

    @doc               = Nokogiri::HTML::DocumentFragment.parse(data)
    @toc_doc           = nil
    @anchor_names      = {}
    @current_ancestors = []
    @headers_levels    = {}
    toc_str            = ''
    if @markup.sub_page && @markup.parent_page
      toc_str = @markup.parent_page.toc_data
    else
      @headers = @doc.css(headers_selector)
      get_toc_levels()

      @headers.each_with_index do |header, i|
        next if header.content.empty?
        # omit the first H1 (the page title) from the TOC if so configured
        next if (i == 0 && header.name =~ /[Hh]1/) && @markup.wiki && @markup.wiki.h1_title

        anchor_name = generate_anchor_name(header)
        add_anchor_to_header header, anchor_name
        add_entry_to_toc     header, anchor_name
      end
      if not @toc_doc.nil?
        toc_str = @toc_doc.to_xml(@markup.class.to_xml_opts)
      end

      data  = @doc.to_xml(@markup.class.to_xml_opts)
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
          if e.name == 'ul' and e.ancestors('ul').length > levels - 1
            e.remove
          end
        end
        toc_clone.to_xml(@markup.class.to_xml_opts)
      end
    end

    data
  end

  private

  def headers_selector
    HEADERS.map { |n| make_header_tag(n) } .join(',')
  end

  def get_header_level(header)
    header.name.match(/[Hh]([1-6])/)[1].to_i
  end

  # Find level as it should be viewed in TOC for each header
  # and save hash to @header_levels
  def get_toc_levels
    stack = []

    @headers.each do |header|
      cur_level = get_header_level(header)

      loop do
        prev_level = stack[-1]
        break if prev_level.nil? || prev_level < cur_level
        stack.pop
      end

      stack.push cur_level
      @headers_levels[header] = stack.size
    end
  end

  # Generates header in format "h<level>"
  def make_header_tag(level)
    raise "Header should be from 1 to 6" unless level.between?(1, 6)
    "h#{level}"
  end

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
    level = header.name[1..-1].to_i

    # normalize the header name
    name.gsub!(/[^\d\w\u00C0-\u1FFF\u2C00-\uD7FF]/, '-')
    name.gsub!(/-+/, '-')
    name.gsub!(/^-/, '')
    name.gsub!(/-$/, '')
    name.downcase!

    # Ensure duplicate anchors have a unique prefix or the toc will break
    index = increment_anchor_index(name)
    index.zero? ? name : "#{name}-#{index}"
  end

  # Creates an anchor element with the given name and adds it before
  # the given header element.
  def add_anchor_to_header(header, name)
    a = Nokogiri::XML::Node.new('a', @doc.document)
    a['class'] = 'anchor'
    a['id'] = name
    a['href'] = "##{name}"
    header.children.before(a) # Add anchor element before the header
  end

  # Adds an entry to the TOC for the given header.  The generated entry
  # is a link to the given anchor name
  def add_entry_to_toc(header, name)
    @toc_doc ||= Nokogiri::XML::DocumentFragment.parse('<div class="toc"><div class="toc-title">Table of Contents</div></div>')
    @tail ||= @toc_doc.child
    @tail_level ||= 0

    level = @headers_levels[header]

    if @tail_level < level
      while @tail_level < level
        list = Nokogiri::XML::Node.new('ul', @doc.document)
        @tail.add_child(list)
        @tail = list.add_child(Nokogiri::XML::Node.new('li', @doc.document))
        @tail_level += 1
      end
    else
      while @tail_level > level
        @tail = @tail.parent.parent
        @tail_level -= 1
      end
      @tail = @tail.parent.add_child(Nokogiri::XML::Node.new('li', @doc.document))
    end

    # % -> %25 so anchors work on Firefox. See issue #475
    @tail.add_child(%Q{<a href="##{name}">#{CGI.escapeHTML(header.content)}</a>})
  end

  # Increments the number of anchors with the given name
  # and returns the current index
  def increment_anchor_index(name)
    @anchor_names = {} if @anchor_names.nil?
    @anchor_names[name].nil? ? @anchor_names[name] = 0 : @anchor_names[name] += 1
  end
end
