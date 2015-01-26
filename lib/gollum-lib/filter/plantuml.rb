# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'uri'
require 'open-uri'
require 'zlib'

# PlantUML Diagrams
#
# This filter replaces PlantUML blocks with HTML img tags. These img tags
# point to a PlantUML web service that converts the UML text blocks into nice
# diagrams.
#
# For this to work you must have your own PlantUML server running somewhere.
# Just follow the instructions on the github page to run your own server:
#
#   https://github.com/plantuml/plantuml-server
#
# Once you start you own plantuml server you need to configure this filter to
# point to it:
#
#   Gollum::Filter::PlantUML.configure do |config|
#     config.url = "http://localhost:8080/plantuml/png"
#   end
#
# Then in your wiki pages simply add PlantUML blocks anywhere you want a
# diagram:
#
#     @startuml
#     Alice -> Bob: Authentication Request
#     Bob --> Alice: Authentication Response
#     Alice -> Bob: Another authentication Request
#     Alice <-- Bob: another authentication Response
#     @enduml
#
# To learn more about how to create cool PlantUML diagrams check the examples
# at: http://plantuml.sourceforge.net/
#
class Gollum::Filter::PlantUML < Gollum::Filter

  DEFAULT_URL = "http://localhost:8080/plantuml/png"

  # Configuration class used to change the behaviour of the PlatnUML filter.
  # Currently only the PlantUML server endpoint can be modified.
  class Configuration
    attr_accessor :url

    def initialize
      @url = DEFAULT_URL
    end
  end

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Extract all sequence diagram blocks into the map and replace with
  # placeholders.
  def extract(data)
    return data if @markup.format == :txt
    data.gsub(/(@startuml\r?\n.+?\r?\n@enduml\r?$)/m) do
      id       = Digest::SHA1.hexdigest($1)
      @map[id] = { :code => $1 }
      id
    end
  end

  # Process all diagrams from the map and replace the placeholders with
  # the final HTML.
  def process(data)
    @map.each do |id, spec|
      data.gsub!(id) do
        render_plantuml(id, spec[:code])
      end
    end
    data
  end

  private

  def server_url
    PlantUML::configuration.url
  end

  def render_plantuml(id, code)
    "<img src=\"#{server_url}/#{gen_url(code)}\" />"
  end

  # Compression code used to generate PlantUML URLs. Taken directly from the
  # Transcoder class in the PlantUML java code.
  def gen_url(text)
    result = ""
    compressedData = Zlib::Deflate.deflate(text)
    compressedData.chars.each_slice(3) do |bytes|
      #print bytes[0], ' ' , bytes[1] , ' ' , bytes[2]
      b1 = bytes[0].nil? ? 0 : (bytes[0].ord & 0xFF)
      b2 = bytes[1].nil? ? 0 : (bytes[1].ord & 0xFF)
      b3 = bytes[2].nil? ? 0 : (bytes[2].ord & 0xFF)
      result += append3bytes(b1, b2, b3)
    end
    result
  end

  def encode6bit(b)
    if b < 10
      return ('0'.ord + b).chr
    end
    b = b - 10
    if b < 26
      return ('A'.ord + b).chr
    end
    b = b - 26
    if b < 26
      return ('a'.ord + b).chr
    end
    b = b - 26
    if b == 0
      return '-'
    end
    if b == 1
      return '_'
    end
    return '?'
  end

  def append3bytes(b1, b2, b3)
    c1 = b1 >> 2
    c2 = ((b1 & 0x3) << 4) | (b2 >> 4)
    c3 = ((b2 & 0xF) << 2) | (b3 >> 6)
    c4 = b3 & 0x3F
    return encode6bit(c1 & 0x3F).chr +
           encode6bit(c2 & 0x3F).chr +
           encode6bit(c3 & 0x3F).chr +
           encode6bit(c4 & 0x3F).chr
  end

end
