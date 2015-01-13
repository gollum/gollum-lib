# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'uri'
require 'open-uri'

# PlantUML Diagrams
#
# Render an inline plantuml diagram by generating a PNG image using the
# plantuml.jar tool.
#
class Gollum::Filter::PlantUML < Gollum::Filter

  JAR = "/home/ryujin/plantuml.jar"
  JAVA = "/home/ryujin/Apps/jdk/bin/java"

  # Extract all sequence diagram blocks into the map and replace with
  # placeholders.
  def extract(data)
    return data if @markup.format == :txt
    data.gsub(/(@startuml\r?\n.+\r?\n@enduml)/m) do
      id       = Digest::SHA1.hexdigest($1)
      @map[id] = { :code => $1 }
      id
    end
  end

  # Process all diagrams from the map and replace the placeholders with
  # the final HTML.
  #
  def process(data)
    @map.each do |id, spec|
      data.gsub!(id) do
        render_plantuml(id, spec[:code])
      end
    end
    data
  end

  private

  def render_plantuml(id, code)
    File.open(id, "w") do |file|
      file << code
    end
    system("#{JAVA} -jar #{JAR} #{id}")
    if $?.success?
      "<img src=\"#{id}.png\" />"
    else
      html_error("failed to generate uml image")
    end
  end
end
