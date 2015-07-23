# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'uri'
require 'open-uri'

# Jumly UML Diagrams
#
# Render an inline jumly uml diagram by sending the jumly code through the
# online renderer available from http://jumly.tmtk.net
#
class Gollum::Filter::JUMLY < Gollum::Filter
  JUMLY_URL = "http://jumly.tmtk.net/api/diagrams?data="

  # Extract all sequence diagram blocks into the map and replace with
  # placeholders.
  def extract(data)
    return data if @markup.format == :txt
    data.gsub(/@startjumly\r?\n(.+?\r?\n)@endjumly\r?$/m) do
      id       = Digest::SHA1.hexdigest($1)
      @map[id] = { :code => $1 }
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
	render_jumly(spec[:code])
      end
    end
    data
  end

  private
  # Render the sequence diagram on the remote server.
  #
  # Returns an <img> tag to the rendered image, or an HTML error.
  def render_jumly(code)
    url = JUMLY_URL + URI::encode(code)
    "<img src=\"#{url}\" />"
  end
end
