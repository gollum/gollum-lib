# ~*~ encoding: utf-8 ~*~

require "pathname"

module Gollum
  module MarkupRegisterUtils
    # Check if a gem exists. This implementation requires Gem::Specificaton to
    # be filled.
    def gem_exists?(name)
      Gem::Specification.find {|spec| spec.name == name} != nil
    end

    # Check if an executable exists. This implementation comes from
    # stackoverflow question 2108727.
    def executable_exists?(name)
      exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
      paths = ENV["PATH"].split(::File::PATH_SEPARATOR)
      paths.each do |path|
        exts.each do |ext|
          exe = Pathname(path) + "#{name}#{ext}"
          return true if exe.executable?
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
        Kramdown::Document.new(content, :auto_ids => false, :smart_quotes => ["'", "'", '"', '"'].map{|char| char.codepoints.first}).to_html
    }

    # markdown, rdoc, and plain text are always supported.
    register(:markdown, "Markdown", :extensions => ['md','mkd','mkdn','mdown','markdown'])
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
             :extensions => ['rest', 'rst', 'rst.txt', 'rest.txt'])
    register(:asciidoc, "AsciiDoc",
             :enabled => MarkupRegisterUtils::gem_exists?("asciidoctor"))
    register(:mediawiki, "MediaWiki",
             :enabled => MarkupRegisterUtils::gem_exists?("wikicloth"),
             :extensions => ['mediawiki','wiki'], :reverse_links => true)
    register(:pod, "Pod",
             :enabled => MarkupRegisterUtils::executable_exists?("perl"))
  end
end
