# ~*~ encoding: utf-8 ~*~

class Gollum::Filter::Sanitize < Gollum::Filter
  def extract(data)
    data
  end

  def process(data)
    if @markup.sanitize
      doc = Nokogiri::HTML::DocumentFragment.parse(data)
      doc = @markup.sanitize.clean_node!(doc)

      doc.to_xml(@markup.to_xml_opts).gsub(/<p><\/p>/, '')
    else
      data
    end
  end
end
