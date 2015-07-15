# ~*~ encoding: utf-8 ~*~

# Source Maps
#
# Find lines corresponding to h1 headers for the present markup and insert markers indicating the line number in the raw source.

class Gollum::Filter::SourceMap < Gollum::Filter
  def extract(data)
  	regex = Gollum::Markup.formats[@markup.format][:h1]
    return data if regex.nil?
    i = 0
    data.lines.map do |line|
    	line = line.sub(regex) do
    		"#{$1}GOLLUMSRCMP#{i}GOLLUMSRCMP#{$2}"
    	end
      i = i + 1
      line
    end.join
  end

  def process(data)
   data
  end
end