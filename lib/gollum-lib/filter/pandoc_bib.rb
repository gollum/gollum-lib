require 'yaml'
require 'pathname'

# When using pandoc, put relevant bibliography metadata extracted in the YAML filter back in the document so it gets passed on to pandoc.
class Gollum::Filter::PandocBib < Gollum::Filter

  BIB_PATH_KEYS = ['bibliography', 'csl']
  BIB_KEYS = ['link-citations', 'nocite']
  ALL_BIB_KEYS = BIB_PATH_KEYS + BIB_KEYS
  
  def process(data)
    data
  end

  def extract(data)
    return data unless supported_format? && bibliography_metadata_present?
    bib_metadata = {}
    bib_metadata.merge!(@markup.metadata.select {|key, _value| BIB_KEYS.include?(key)})

    BIB_PATH_KEYS.each do |bibliography_key|
      if path = @markup.metadata[bibliography_key]
        next unless file = @markup.wiki.file(path)
        bib_metadata[bibliography_key] = path_for_bibfile(file)
      end
    end
    bib_metadata.empty? ? data : "#{bib_metadata.to_yaml}---\n#{data}"
  end

  private

  def path_for_bibfile(file)
    if @markup.wiki.repo_is_bare
      path = Pathname.new("#{::File.join(::Dir.tmpdir, file.sha)}#{::File.extname(file.path)}")
        unless path.exist?
          path.open('w') do |copy_file|
            copy_file.write(file.raw_data)
          end
        end
      path.to_s
    else
      ::File.expand_path(::File.join(@markup.wiki.path, file.path))
    end
  end

  def supported_format?
    @markup.format == :markdown
  end

  def bibliography_metadata_present?
     @markup.metadata && @markup.metadata.keys.any? {|key| ALL_BIB_KEYS.include?(key)}
  end
end
