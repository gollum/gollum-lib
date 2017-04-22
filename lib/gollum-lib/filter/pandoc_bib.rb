require 'yaml'
require 'pathname'

class Gollum::Filter::PandocBib < Gollum::Filter
  
  def process(data)
    data
  end

  def extract(data)
    return data unless @markup.metadata
    bib_metadata = {}

    ['bibliography', 'csl'].each do |bibliography_key|
      if path = @markup.metadata[bibliography_key]
        next unless file = @markup.wiki.file(path)
        path = Pathname.new("#{::File.join(::Dir.tmpdir, file.sha)}#{::File.extname(path)}")
        bib_metadata[bibliography_key] = path.to_s
        unless path.exist?
          path.open('w') do |copy_file|
            copy_file.write file.raw_data
          end
        end
      end
    end
    bib_metadata.empty? ? data : "#{bib_metadata.to_yaml}---\n#{data}"
  end
end
