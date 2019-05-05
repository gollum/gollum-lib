# ~*~ encoding: utf-8 ~*~

class Gollum::Filter::Render < Gollum::Filter
  def extract(data)
    begin
      if @markup.wiki.repo_is_bare
        working_dir = '.'
      else
        working_dir = ::File.join(@markup.wiki.path, @markup.dir)
        working_dir = '.' unless ::File.exists?(working_dir)
      end
      Dir.chdir(working_dir) do
        data = GitHub::Markup.render(@markup.name, data)
      end
      if data.nil?
        raise "There was an error converting #{@markup.name} to HTML."
      end
    rescue Object => e
      data = html_error("Failed to render page: #{e.message}")
    end

    data
  end

  def process(data)
    data = add_editable_header_class(data)
    data
  end

  private

  def add_editable_header_class(data)
    doc = Nokogiri::HTML::DocumentFragment.parse(data)
    doc.css('h1,h2,h3,h4,h5,h6').each_with_index do |header, i|
      next if header.content.empty?
      next if header.inner_html.match(PLACEHOLDER_PATTERN)
      klass = header['class']
      if klass
        header['class'] = klass << ' editable'
      else
        header['class'] = 'editable'
      end
    end
    doc.to_xml(@markup.to_xml_opts)
  end

end
