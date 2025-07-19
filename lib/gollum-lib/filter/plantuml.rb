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
  UML_KINDS = ['uml', 'json', 'yaml', 'ebnf', 'regex', 'salt', 'ditaa', 'gantt', 'chronology', 'mindmap', 'wbs', 'math', 'latex', 'chen']
  UML_REGEX = /\s*(@start(#{Regexp.union(UML_KINDS)})([ \t\f\v]+[^\r\n]+|[ \t\r\f\v]*)\n.+?\r?\n@end\2\r?$)/m
  DEFAULT_URL = 'http://localhost:8080/plantuml/png'

  # Configuration class used to change the behaviour of the PlatnUML filter.
  #
  #   url: PlantUML server URL (e.g. http://localhost:8080)
  #   test: Set to true when running tests to skip the server check.
  #
  class Configuration
    attr_accessor :url, :test, :verify_ssl

    def initialize
      @url = DEFAULT_URL
      @verify_ssl = true
      @test = false
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
    data.gsub(UML_REGEX) do
      id       = "#{open_pattern}#{Digest::SHA1.hexdigest($1)}#{close_pattern}"
      @map[id] = { :code => $1 }
      id
    end
  end

  # Process all diagrams from the map and replace the placeholders with
  # the final HTML.
  def process(data)
    @map.each do |id, spec|
      data.gsub!(id) do
        render_plantuml(spec[:code])
      end
    end
    data
  end

  def render_plantuml(code)
    if check_server
      plantuml_url = gen_url(code)
      "<img src=\"#{gen_url(code)}\" />"
    else
      html_error("Sorry, unable to render PlantUML diagram at this time")
    end
  end

  private

  def server_url
    PlantUML::configuration.url
  end

  def test?
    PlantUML::configuration.test
  end

  def verify_ssl?
    PlantUML::configuration.verify_ssl
  end

  # Compression code used to generate PlantUML URLs. Taken directly from the
  # Transcoder class in the PlantUML java code.
  def gen_url(text)
    result = ""
    compressedData = Zlib::Deflate.new(nil, -Zlib::MAX_WBITS).deflate(text, Zlib::FINISH)

    compressedData.chars.each_slice(3) do |bytes|
      b1 = bytes[0].nil? ? 0 : (bytes[0].ord & 0xFF)
      b2 = bytes[1].nil? ? 0 : (bytes[1].ord & 0xFF)
      b3 = bytes[2].nil? ? 0 : (bytes[2].ord & 0xFF)
      result += append3bytes(b1, b2, b3)
    end
    "#{server_url}/#{result}"
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

  # Make a call to the PlantUML server with the simplest diagram possible to
  # check if the server is available or not.
  def check_server
    return true if test?
    check_url = "#{server_url}/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"
    uri = URI.parse(check_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless verify_ssl?
    response = http.request_get(uri.request_uri)
    return response.is_a?(Net::HTTPSuccess)
  rescue
    return false
  end
end

Gollum::Filter::Code.language_handlers[/plantuml/] = Proc.new {
  |lang, code| Gollum::Filter::PlantUML.new(code).render_plantuml("@startuml\n#{code}\n@enduml\n")
}
