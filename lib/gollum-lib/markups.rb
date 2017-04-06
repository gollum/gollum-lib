# ~*~ encoding: utf-8 ~*~
module Gollum
  module MarkupRegisterUtils
    # Check if a gem exists. This implementation requires Gem::Specificaton to
    # be filled.
    def gem_exists? name
      return Gem::Specification.find {|x| x.name == name} != nil
    end

    # Check if an executable exsits. This implementation comes from
    # stackoverflow question 2108727.
    def executable_exists? name
      exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
      paths = ENV["PATH"].split(::File::PATH_SEPARATOR)
      paths.each do |path|
        exts.each do |ext|
          exe = ::File.join(path, "#{name}#{ext}")
          return true if ::File.executable?(exe) && !::File.directory?(exe)
        end
      end
      return false
    end
  end
end

include Gollum::MarkupRegisterUtils

module Gollum
  class Markup
    GitHub::Markup::Markdown::MARKDOWN_GEMS['kramdown'] = proc { |content|
      Kramdown::Document.new(content, :auto_ids => false, :input => "markdown").to_html
    }

    # markdown, rdoc, and plain text is always supported.
    register(:markdown,    "Markdown", :regexp => /md|mkdn?|mdown|markdown/)
    register(:rdoc,        "RDoc")
    register(:txt,         "Plain Text")

    if MarkupRegisterUtils::gem_exists? "RedCloth"
      register(:textile,   "Textile")
    end
    if MarkupRegisterUtils::gem_exists? "org-ruby"
      register(:org,       "Org-mode")
    end
    if MarkupRegisterUtils::gem_exists? "creole"
      register(:creole,    "Creole", :reverse_links => true)
    end
    if MarkupRegisterUtils::executable_exists? "python2"
      register(:rest,      "reStructuredText", :regexp => /re?st(\.txt)?/)
    end
    if MarkupRegisterUtils::gem_exists? "asciidoctor"
      register(:asciidoc,  "AsciiDoc")
    end
    if MarkupRegisterUtils::gem_exists? "wikicloth"
      register(:mediawiki, "MediaWiki", :regexp => /(media)?wiki/, :reverse_links => true)
    end
    if MarkupRegisterUtils::executable_exists? "perl"
      register(:pod,       "Pod")
    end
  end
end
