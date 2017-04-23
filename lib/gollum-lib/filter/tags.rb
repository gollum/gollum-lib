# ~*~ encoding: utf-8 ~*~

# Render all tags (things in double-square-brackets).  This one's a biggie.
class Gollum::Filter::Tags < Gollum::Filter
  # Extract all tags into the tagmap and replace with placeholders.
  def extract(data)
    return data if @markup.skip_tags?

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
        content.gsub!(/TAG[a-f0-9]+TAG/) do |id|
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

  def register_tag(tag)
    id       = "TAG#{Digest::SHA1.hexdigest(tag)}TAG"
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
    mime = MIME::Types.type_for(::File.extname(link_part.to_s)).first

    result = if link_part =~ /^_TOC_/
      %{[[#{tag}]]}
    elsif link_part =~ /^_$/
      %{<div class="clearfloats"></div>}
    elsif link_part =~ /^include:/
      process_include_tag(link_part)
    elsif mime && mime.content_type =~ /^image/
      process_image_tag(link_part, extra)
    elsif external = process_external_link_tag(extra, link_part)
      external
    end
    result ? result : process_link_tag(link_part, extra)
  end

  def process_link_tag(link_part, extra)
    process_file_link_tag(link_part, extra) || process_page_link_tag(link_part, extra)
  end

  def parse_tag_parts(tag)
    parts = tag.split('|').map(&:strip)
    parts.reverse! if @markup.reverse_links?
    parts
  end

  # Attempt to process the tag as an include tag
  #
  # tag - The String tag contents (the  stuff inside the double brackets).
  #
  # Returns the String HTML if the tag is a valid image tag or nil
  #   if it is not.
  #
  def process_include_tag(tag)
    return html_error('Cannot process include directive: no page name given') if tag.length <= 8
    page_name          = tag[8..-1]
    resolved_page_name = ::File.expand_path(page_name, "#{::File::SEPARATOR}#{@markup.dir}")
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
  # tag - The String tag contents (the stuff inside the double brackets).
  #
  # Returns the String HTML if the tag is a valid image tag or nil
  #   if it is not.
  def process_image_tag(name, options = nil)
    if name =~ /^https?:\/\/.+$/i
      path = name
    elsif (file = @markup.find_file(name))
      path = ::File.join @markup.wiki.base_path, file.path
    else
      # If is image, file not found and no link, then populate with empty String
      # We can than add an image not found alt attribute for this later
      path = ""
    end

    if path
      opts = parse_image_tag_options(options)

      containered = false

      classes = [] # applied to whatever the outermost container is
      attrs   = [] # applied to the image

      align = opts['align']
      if opts['float']
        containered = true
        align       ||= 'left'
        if %w{left right}.include?(align)
          classes << "float-#{align}"
        end
      elsif %w{top texttop middle absmiddle bottom absbottom baseline}.include?(align)
        attrs << %{align="#{align}"}
      elsif align
        if %w{left center right}.include?(align)
          containered = true
          classes << "align-#{align}"
        end
      end

      if (width = opts['width'])
        if width =~ /^\d+(\.\d+)?(em|px)$/
          attrs << %{width="#{width}"}
        end
      end

      if (height = opts['height'])
        if height =~ /^\d+(\.\d+)?(em|px)$/
          attrs << %{height="#{height}"}
        end
      end

      if path != "" && (alt = opts['alt'])
        attrs << %{alt="#{alt}"}
      elsif path == ""
        attrs << %{alt="Image not found"}
      end

      attr_string = attrs.size > 0 ? attrs.join(' ') + ' ' : ''

      if opts['frame'] || containered
        classes << 'frame' if opts['frame']
        %{<span class="#{classes.join(' ')}">} +
            %{<span>} +
            %{<img src="#{path}" #{attr_string}/>} +
            (alt ? %{<span>#{alt}</span>} : '') +
            %{</span>} +
            %{</span>}
      else
        %{<img src="#{path}" #{attr_string}/>}
      end
    end
  end

  # Parse any options present on the image tag (space separated) and extract them into a
  # Hash of option names and values.
  #
  # tag - The String tag contents (the stuff inside the double brackets).
  #
  # Returns the options Hash:
  #   key - The String option name.
  #   val - The String option value or true if it is a binary option.
  def parse_image_tag_options(options)
    return {} if options.nil?
    options.split(',').inject({}) do |memo, attr|
      parts          = attr.split('=').map { |x| x.strip }
      memo[parts[0]] = (parts.size == 1 ? true : parts[1])
      memo
    end
  end

  # Return the String HTML if the tag is a valid external link tag or
  # nil if it is not.
  def process_external_link_tag(url, name = nil)
    url = name if url.nil? && name
    accepted_protocols = @markup.wiki.sanitization.protocols['a']['href'].dup
    if accepted_protocols.include?(:relative)
      accepted_protocols.select!{|protocol| protocol != :relative}
      regexp = %r{^((#{accepted_protocols.join("|")}):)?(//)}
    else
      regexp = %r{^((#{accepted_protocols.join("|")}):)}
    end
    if url =~ regexp
      if name.nil?
        %{<a href="#{url}">#{url}</a>}
      else
        %{<a href="#{url}">#{name}</a>}
      end
    else
      nil
    end

  end

  # Attempt to process the tag as a file link tag.
  #
  # tag       - The String tag contents (the stuff inside the double
  #             brackets).
  #
  # Returns the String HTML if the tag is a valid file link tag or nil
  #   if it is not.
  def process_file_link_tag(name, path)
    if path && file = @markup.find_file(path)
      path = ::File.join @markup.wiki.base_path, file.path
    else
      path = nil
    end

    if name && path && file
      %{<a href="#{::File.join @markup.wiki.base_path, file.path}">#{name}</a>}
    elsif name && path
      %{<a href="#{path}">#{name}</a>}
    else
      nil
    end
  end

  # Attempt to process the tag as a page link tag.
  #
  # tag       - The String tag contents (the stuff inside the double
  #             brackets).
  #
  # Returns the String HTML if the tag is a valid page link tag or nil
  #   if it is not.
  def process_page_link_tag(name, page_name = nil)
    link            = page_name ? page_name : name.to_s
    presence    = "absent"
    page = find_page_from_path(link)

    # If no match yet, try finding page with anchor removed
    if (page.nil? && pos = link.rindex('#'))
      extra     = link[pos..-1]
      link      = link[0...pos]
      page      = find_page_from_path(link)
    end
    presence  = "present" if page

    link = ::File.join(@markup.wiki.base_path, page ? page.escaped_url_path : CGI.escape(link))
    # strip all duplicate forward slashes using helpers.rb trim_leading_slash
    # //page => /page
    link = trim_leading_slash link

    %{<a class="internal #{presence}" href="#{link}#{extra}">#{name}</a>}
  end

  # Find a page from a given path
  #
  # path - The String path to search for.
  #
  # Returns a Gollum::Page instance if a page is found, or nil otherwise
  def find_page_from_path(path)
    slash = path.rindex('/')

    unless slash.nil?
      name = path[slash+1..-1]
      path = path[0..slash]
      @markup.wiki.paged(name, path)
    else
      @markup.wiki.page(path)
    end
  end
end
