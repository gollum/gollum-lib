begin
  require 'bibtex'
  require 'citeproc'
  require 'csl/styles'
rescue LoadError => error
  puts "Error trying to require an optional gem for BibTeX parsing: #{error.to_s}"
end

# Render BibTeX files.
class Gollum::Filter::BibTeX < Gollum::Filter

  def extract(data)
    return data unless supported_format? && gems_available? && bib = ::BibTeX.parse(data).convert(:latex)
    style = @markup.metadata['bibstyle'] if @markup.metadata
    begin
      style = ::CSL::Style.load(style.to_sym) if style
    rescue ::CSL::ParseError
      style = nil
    end
    citeproc = ::CiteProc::Processor.new(style: style || 'apa', format: 'html')
    citeproc.import(bib.to_citeproc)
    citeproc.bibliography.references.join("<br/>")
  end

  def process(data)
    data
  end

  private

  def supported_format?
    @markup.format == :bib
  end

  def gems_available?
    ::Gollum::MarkupRegisterUtils::gems_exist?(["bibtex-ruby", "citeproc-ruby", "csl"])
  end
end
