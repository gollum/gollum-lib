# ~*~ encoding: utf-8 ~*~
module Gollum
  module MarkupRegisterUtils
    # Check if a gem exists. This implementation requires Gem::Specificaton to
    # be filled.
    def gem_exists? name
      return Gem::Specification.find {|x| x.name == name} != nil
    end

    # Check if an executable exists. This implementation comes from
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

    # markdown, rdoc, and plain text are always supported.
    register(:markdown, "Markdown", :regexp => /md|mkdn?|mdown|markdown/)
    register(:rdoc, "RDoc")
    register(:txt, "Plain Text")
    # the following formats are available only when certain gem is installed
    # or certain program exists.
    register(:textile, "Textile",
             :enabled => MarkupRegisterUtils::gem_exists?("RedCloth"))
    register(:org, "Org-mode",
             :enabled => MarkupRegisterUtils::gem_exists?("org-ruby"))
    register(:creole, "Creole",
             :enabled => MarkupRegisterUtils::gem_exists?("creole"),
             :reverse_links => true)
    register(:rest, "reStructuredText",
             :enabled => MarkupRegisterUtils::executable_exists?("python2"),
             :regexp => /re?st(\.txt)?/)
    register(:asciidoc, "AsciiDoc",
             :enabled => MarkupRegisterUtils::gem_exists?("asciidoctor"))
    register(:mediawiki, "MediaWiki",
             :enabled => MarkupRegisterUtils::gem_exists?("wikicloth"),
             :regexp => /(media)?wiki/, :reverse_links => true)
    register(:pod, "Pod",
             :enabled => MarkupRegisterUtils::executable_exists?("perl"))
  end
end
