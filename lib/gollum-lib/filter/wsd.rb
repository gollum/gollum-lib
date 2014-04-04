# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'uri'
require 'open-uri'

# Web Sequence Diagrams
#
# Render an inline web sequence diagram by sending the WSD code through the
# online renderer available from www.websequencediagrams.com.
#
class Gollum::Filter::WSD < Gollum::Filter
  WSD_URL = "http://www.websequencediagrams.com/index.php"

  # Extract all sequence diagram blocks into the map and replace with
  # placeholders.
  def extract(data)
    return data if @markup.format == :txt
    data.gsub(/^\{\{\{\{\{\{ ?(.+?)\r?\n(.+?)\r?\n\}\}\}\}\}\}\r?$/m) do
      id       = Digest::SHA1.hexdigest($2)
      @map[id] = { :style => $1, :code => $2 }
      id
    end
  end

  # Process all diagrams from the map and replace the placeholders with
  # the final HTML.
  #
  # data - The String data (with placeholders).
  #
  # Returns the marked up String data.
  def process(data)
    @map.each do |id, spec|
      data.gsub!(id) do
        render_wsd(spec[:code], spec[:style])
      end
    end
    data
  end

  private
  # Render the sequence diagram on the remote server.
  #
  # Returns an <img> tag to the rendered image, or an HTML error.
  def render_wsd(code, style)
    response = Net::HTTP.post_form(URI.parse(WSD_URL), 'style' => style, 'message' => code)
    if response.body =~ /img: "(.+)"/
      url = "http://www.websequencediagrams.com/#{$1}"
      "<img src=\"#{url}\" />"
    else
      puts response.body
      html_error("Sorry, unable to render sequence diagram at this time.")
    end
  end
end
