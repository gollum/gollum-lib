require 'yaml'
require 'pathname'

class Gollum::Filter::PandocBib < Gollum::Filter

  BIB_KEYS = ['bibliography', 'csl']
  
  def process(data)
    data
  end

  def extract(data)
    return data unless @markup.format == :markdown && @markup.metadata && bibliography_metadata_present? && using_pandoc?
    bib_metadata = {}

    BIB_KEYS.each do |bibliography_key|
      path = @markup.metadata[bibliography_key]
      next unless file = @markup.wiki.file(path)
      path = Pathname.new("#{::File.join(::Dir.tmpdir, file.sha)}#{::File.extname(path)}")
      bib_metadata[bibliography_key] = path.to_s
      unless path.exist?
        path.open('w') do |copy_file|
          copy_file.write file.raw_data
        end
      end
    end
    bib_metadata.empty? ? data : "#{bib_metadata.to_yaml}---\n#{data}"
  end

  private

  def using_pandoc?
    GitHub::Markup::Markdown.new.implementation_name == 'pandoc-ruby'
  end

  def bibliography_metadata_present?
    @markup.metadata.keys.any? {|key| BIB_KEYS.include?(key)}
  end
end
