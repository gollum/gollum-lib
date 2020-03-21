# ~*~ encoding: utf-8 ~*~

# Render all tags (things in double-square-brackets).  This one's a biggie.
class Gollum::Filter::Tags < Gollum::Filter
  # Extract all tags into the tagmap and replace with placeholders.
  def extract(data)
    data.gsub!(/(.?)\[\[(.+?)\]\]([^\[]?)/) do
      if Regexp.last_match[1] == "'" && Regexp.last_match[3] != "'"
        "[[#{Regexp.last_match[2]}]]#{Regexp.last_match[3]}"
      elsif Regexp.last_match[2].include?('][')
        if Regexp.last_match[2][0..4] == 'file:'
          pre            = Regexp.last_match[1]
          post           = Regexp.last_match[3]
          parts          = Regexp.last_match[2].split('][')
          parts[0][0..4] = ""
          link           = "#{parts[1]}|#{parts[0].sub(/\.org/, '')}"
          id             = register_tag(link)
          "#{pre}#{id}#{post}"
        else
          Regexp.last_match[0]
        end
      else
        id = register_tag(Regexp.last_match[2])
        "#{Regexp.last_match[1]}#{id}#{Regexp.last_match[3]}"
      end
    end
    data
  end

  # Process all text nodes from the doc and replace the placeholders with the
  # final markup.
  def process(rendered_data)
    doc  = Nokogiri::HTML::DocumentFragment.parse(rendered_data)
    doc.traverse do |node|
      if node.text? then
        content = node.content
        content.gsub!(%r{#{open_pattern}[a-f0-9]+#{close_pattern}}) do |id|
          if (tag = @map[id]) then
            if is_preformatted?(node) then
              "[[#{tag}]]"
            else
              process_tag(tag).gsub('%2f', '/')
            end
          end
        end
        node.replace(content) if content != node.content
      end
    end

    doc.to_html
  end

  private

  PREFORMATTED_TAGS = %w(code tt)
  INCLUDE_TAG = 'include:'

  def register_tag(tag)
    id       = "#{open_pattern}#{Digest::SHA1.hexdigest(tag)}#{close_pattern}"
    @map[id] = tag
    id
  end

  def is_preformatted?(node)
    node && (PREFORMATTED_TAGS.include?(node.name) ||
        node.ancestors.any? { |a| PREFORMATTED_TAGS.include?(a.name) })
  end

  # Process a single tag into its final HTML form.
  #
  # tag       - The String tag contents (the stuff inside the double
  #             brackets).
  #
  # Returns the String HTML version of the tag.
  def process_tag(tag)
    link_part, extra = parse_tag_parts(tag)
    return generate_link('', nil, nil, :page_absent) if link_part.nil?
    img_args = extra ? [extra, link_part] : [link_part]
    mime = MIME::Types.type_for(::File.extname(img_args.first.to_s)).first
    result = if tag =~ /^_TOC_/
      %{[[#{tag}]]}
    elsif link_part =~ /^_$/
      %{<div class="clearfloats"></div>}
    elsif link_part =~ /^#{INCLUDE_TAG}/
      process_include_tag(link_part)
    elsif mime && mime.content_type =~ /^image/
      process_image_tag(*img_args)
    elsif external = process_external_link_tag(link_part, extra)
      external
    end
    result ? result : process_link_tag(link_part, extra)
  end

  # Process the tag parts as an internal link to a File or Page. 
  def process_link_tag(link_part, pretty_name)
    process_file_link_tag(link_part, pretty_name) || process_page_link_tag(link_part, pretty_name)
  end
  
  # Parse the tag (stuff between the double brackets) into a link part and additional information (a pretty name, description, or image options).
  #
  # tag       - The String tag contents (the stuff inside the double
  #             brackets).
  #
  # Returns an Array of the form [link_part, extra], where both elements are Strings and the second element may be nil.
  def parse_tag_parts(tag)
    parts = tag.split('|').map(&:strip)[0..1]
    parts.reverse! if @markup.reverse_links?
    if parts[1]
      return parts[1], parts[0]
    else
      return parts[0], nil
    end
  end

  # Attempt to process the tag as an include tag
  #
  # tag - The String tag contents (the  stuff inside the double brackets).
  #
  # Returns the String HTML if the tag includes a valid page or an error message if the page could not be found.
  def process_include_tag(tag)
    len = INCLUDE_TAG.length
    return html_error('Cannot process include directive: no page name given') if tag.length <= len
    page_name          = tag[len..-1]
    resolved_page_name = ::File.join(@markup.dir, page_name)
    if @markup.include_levels > 0
      page = find_page_from_path(resolved_page_name)
      if page
        page.formatted_data(@markup.encoding, @markup.include_levels-1)
      else
        html_error("Cannot include #{process_page_link_tag(resolved_page_name)} - does not exist yet")
      end
    else
      html_error("Too many levels of included pages, will not include #{process_page_link_tag(resolved_page_name)}")
    end
  end

  # Attempt to process the tag as an image tag.
  #
  # path - The String path to the image.
  # options - The String of options for the image (the stuff after the '|'). Optional.
  #
  # Returns the String HTML if the tag is a valid image tag or nil
  #   if it is not.
  def process_image_tag(path, options = nil)
    opts = parse_image_tag_options(options)
    if path =~ /^https?:\/\/.+$/i
      generate_image(path, opts)
    elsif file = @markup.find_file(path)
      generate_image(generate_href_for_path(file.url_path), opts)
    else
      generate_image('', opts)
    end
  end

  # Parse any options present on the image tag (comma separated) and extract them into a
  # Hash of option names and values.
  #
  # options - The String image options (the stuff in the after '|').
  #
  # Returns the options Hash:
  #   key - The String option name.
  #   val - The String option value or true if it is a binary option.
  def parse_image_tag_options(options)
    return {} if options.nil?
    options.split(',').inject({}) do |memo, attr|
      parts                 = attr.split('=').map { |x| x.strip }
      memo[parts[0].to_sym] = (parts.size == 1 ? true : parts[1])
      memo
    end
  end

  # Return the String HTML if the tag is a valid external link tag or
  # nil if it is not.
  def process_external_link_tag(url, pretty_name = nil)
    @accepted_protocols_regex ||= %r{^((#{::Gollum::Sanitization.accepted_protocols.join('|')}):)?(//)} 
    if url =~ @accepted_protocols_regex
      generate_link(url, pretty_name, nil, :external)
    else
      nil
    end
  end

  # Attempt to process the tag as a file link tag.
  #
  # link_part      - The String part of the tag containing the link
  # pretty_name    - The String name for the link (optional)
  #
  # Returns the String HTML if the tag is a valid file link tag or nil
  #   if it is not.
  def process_file_link_tag(link_part, pretty_name)
    return nil if ::Gollum::Page.valid_extension?(link_part)
    if file = @markup.find_file(link_part)
      generate_link(file.url_path, pretty_name, nil, :file)
    else
      nil
    end
  end

  # Attempt to process the tag as a page link tag.
  #
  # link_part      - The String part of the tag containing the link
  # pretty_name    - The String name for the link (optional)
  #
  # Returns the String HTML if the tag is a valid page link tag or nil
  #   if it is not.
  def process_page_link_tag(link_part, pretty_name = nil)
    presence  = :page_absent
    link      = link_part
    page      = find_page_from_path(link)

    # If no match yet, try finding page with anchor removed
    if page.nil?
      if pos = link.rindex('#')
        extra = link[pos..-1]
        link  = link[0...pos]
      else
        extra = nil
      end

      if link.empty? && extra # Internal anchor link, don't search for the page but return immediately
        return generate_link(nil, pretty_name, extra, :internal_anchor)
      end

      page  = find_page_from_path(link)
    end
    presence = :page_present if page
    
    if pretty_name
      name = pretty_name
    else
      name = page ? path_to_link_text(link) : link
    end
    link = page ? page.escaped_url_path : ERB::Util.url_encode(link).force_encoding('utf-8')
    generate_link(link, name, extra, presence)
  end

  # Find a page from a given path
  #
  # path - The String path to search for.
  #
  # Returns a Gollum::Page instance if a page is found, or nil otherwise
  def find_page_from_path(path)
    if Pathname.new(path).relative?
      page = @markup.wiki.page(::File.join(@markup.dir, path))
      if page.nil? && @markup.wiki.link_compatibility # 4.x link compatibility option. Slow!
        page = @markup.wiki.pages.detect {|page| page.path =~ /^(.*\/)?#{path}\..+/i}
      end
      page
    else
      @markup.wiki.page(path)
    end
  end

  # Generate an HTML link tag.
  #
  # path     - The String path (href) to construct a link to.
  # name     - The String name of the link (text inside the link tag). Optional.
  # extra    - The String anchor to add the link. Optional.
  # kind     - A Symbol indicating whether this is a Page, File, or External link.
  #
  # Returns a String HTML link tag.
  def generate_link(path, name = nil, extra = nil, kind = nil)
    url = kind == :external ? path : generate_href_for_path(path, extra)
    %{<a #{css_options_for_link(kind)} href="#{url}">#{name || path}</a>}
  end

  # Generate a normalized href for a path, taking into consideration the wiki's path settings.
  #
  # path     - The String path to generate an href for.
  # extra    - The String anchor to add to the href. Optional.
  #
  # Returns a String href.
  def generate_href_for_path(path, extra = nil)
    return extra if !path && extra # Internal anchor link
    "#{trim_leading_slashes(::File.join(@markup.wiki.base_path, path))}#{extra}"
  end

  # Construct a CSS class and attribute string for different kinds of links: internal Pages (absent or present) and Files, and External links.
  #
  # kind     - The Symbol indicating the kind of link. Can be one of: :page_absent, :page_present, :file, :external.
  # 
  # Returns the String CSS class and attributes.
  def css_options_for_link(kind)
    case kind
    when :page_absent
      'class="internal absent"'
    when :page_present
      'class="internal present"'
    when :internal_anchor
      'class="internal anchorlink"'
    when :file
      nil
    when :external
      nil
    else
      nil
    end
  end

  # Generate an HTML image tag.
  #
  # path     - The String path (href) of the image.
  # options  - The Hash of parsed image options.
  #
  # Returns a String HTML img tag.
  def generate_image(path, options = nil)
    classes, attrs, containered = generate_image_attributes(options)
    attrs[:alt] = 'Image not found' if path.empty?
    attr_string = attrs.map {|key, value| "#{key}=\"#{value}\""}.join(' ')

    if containered
      %{<span class="d-flex #{classes[:container].join(' ')}">} +
          %{<span class="#{classes[:nested].join(' ')}">} +
          %{<img src="#{path}" #{attr_string}/>} +
          (options[:frame] && attrs[:alt] ? %{<span class="clearfix">#{attrs[:alt]}</span>} : '') +
          %{</span>} +
          %{</span>}
    else
      %{<img src="#{path}" #{attr_string}/>}
    end
  end

  # Helper method to generate the styling attributes and elements for an image tag.
  #
  # options  - The Hash of parsed image options.
  #
  # Returns a Hash containing CSS class Arrays, a Hash of CSS attributes, and a Boolean indicating whether or not the image is containered.
  def generate_image_attributes(options)
    containered = false
    classes = {container: [], nested: []} # applied to the container(s)
    attrs   = {} # applied to the image

    align = options[:align]
    if options[:float]
      containered = true
      align = 'left' unless align == 'right'
      classes[:container] << "float-#{align} pb-4"
    elsif %w{top texttop middle absmiddle bottom absbottom baseline}.include?(align)
      attrs[:align] = align
    elsif align
      if %w{left center right}.include?(align)
        containered = true
        text_align = "text-#{align}"
        align = 'end' if align == 'right'
        classes[:container] << "flex-justify-#{align} #{text_align}"
      end
    end

    if options[:frame] 
      containered = true
      classes[:nested] << 'border p-4'
    end

    attrs[:alt]    = options[:alt]    if options[:alt]
    attrs[:width]  = options[:width]  if options[:width]  =~ /^\d+(\.\d+)?(em|px)$/
    attrs[:height] = options[:height] if options[:height] =~ /^\d+(\.\d+)?(em|px)$/

    return classes, attrs, containered
  end
end
