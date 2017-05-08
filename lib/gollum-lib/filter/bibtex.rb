begin
  require 'bibtex'
  require 'citeproc'
  require 'csl'
  require 'csl/styles'
rescue LoadError => error
end

# Render BibTeX files.
class Gollum::Filter::BibTeX < Gollum::Filter

  def extract(data)
    return data unless supported_format? && gems_available? && bib = ::BibTeX.parse(data).convert(:latex)
    style = find_csl_data('csl') || ::CSL::Style.default
    locale = find_csl_data('locale') || ::CSL::Locale.default

    begin
      style = ::CSL::Style.load(style)
      ::CSL::Locale.load(locale)
    rescue ::CSL::ParseError => error
      log_failure(error.to_s)
      return CGI.escapeHTML(data)
    end

    citeproc = ::CiteProc::Processor.new(style: style, locale: locale, format: 'html')
    citeproc.import(bib.to_citeproc)
    citeproc.bibliography.references.join('<br/>')
  end

  def process(data)
    data
  end

  private

  def log_failure(msg)
    @markup.metadata = {} unless @markup.metadata
    @markup.metadata['errors'] = [] unless @markup.metadata['errors']
    @markup.metadata['errors'] << "Could not render the bibliography because no valid CSL or locale file was found in the wiki or in the CSL directory. Please commited a valid file, or install the csl-styles gem. The message from the parser was: #{msg.to_s}."
  end

  def supported_format?
    @markup.format == :bib
  end

  def gems_available?
    ::Gollum::Markup.formats[:bib][:enabled]
  end

  def find_csl_data(key)
    path = @markup.metadata ? @markup.metadata[key] : nil
    file = path ? @markup.wiki.file(path) : nil
    file.nil? ? path : file.raw_data
  end
end
