# ~*~ encoding: utf-8 ~*~

require 'pathname'

module Gollum
  module MarkupRegisterUtils

    # Check if a gem exists. This implementation requires Gem::Specificaton to
    # be filled.
    def gem_exists?(name)
      Gem::Specification.find {|spec| spec.name == name} != nil
    end

    def all_gems_available?(names)
      names.each do |name|
        return false unless gem_exists?(name)
      end
      true
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

    # Whether the current markdown renderer is pandoc
    def using_pandoc?
      GitHub::Markup::Markdown.implementation_name == 'pandoc-ruby'
    end
  end
end

include Gollum::MarkupRegisterUtils

module GitHub
  module Markup
    class Markdown < Implementation
      class << self
        def implementation_name
          @implementation_name ||= MARKDOWN_GEMS.keys.detect {|gem_name| self.new.send(:try_require, gem_name) }
        end
      end
    end
  end
end

module Gollum
  class Markup
    if gem_exists?('pandoc-ruby')
      GitHub::Markup::Markdown::MARKDOWN_GEMS.delete('kramdown')
      GitHub::Markup::Markdown::MARKDOWN_GEMS['pandoc-ruby'] = proc { |content|
          PandocRuby.convert(content, :from => :markdown, :to => :html, :filter => 'pandoc-citeproc')
      }
    else
      GitHub::Markup::Markdown::MARKDOWN_GEMS['kramdown'] = proc { |content|
          Kramdown::Document.new(content, :input => "GFM", :hard_wrap => 'false', :auto_ids => false, :math_engine => nil, :smart_quotes => ["'", "'", '"', '"'].map{|char| char.codepoints.first}).to_html
      }
    end

    # markdown, rdoc, and plain text are always supported.
    register(:markdown, "Markdown", :extensions => ['md','mkd','mkdn','mdown','markdown'])
    register(:rdoc, "RDoc")
    register(:txt, "Plain Text",
             :skip_filters => Proc.new {|filter| ![:PlainText,:YAML].include?(filter) })
    # the following formats are available only when certain gem is installed
    # or certain program exists.
    register(:textile, "Textile",
             :enabled => MarkupRegisterUtils::gem_exists?("RedCloth"))
    register(:org, "Org-mode",
             :enabled => MarkupRegisterUtils::gem_exists?("org-ruby"))
    register(:creole, "Creole",
             :enabled => MarkupRegisterUtils::gem_exists?("creole"),
             :reverse_links => true)
    register(:rst, "reStructuredText",
             :enabled => MarkupRegisterUtils::executable_exists?("python2"),
             :extensions => ['rest', 'rst'])
    register(:asciidoc, "AsciiDoc",
             :skip_filters => [:Tags],
             :enabled => MarkupRegisterUtils::gem_exists?("asciidoctor"),
             :extensions => ['adoc','asciidoc'])
    register(:mediawiki, "MediaWiki",
             :enabled => MarkupRegisterUtils::gem_exists?("wikicloth"),
             :extensions => ['mediawiki','wiki'], :reverse_links => true)
    register(:pod, "Pod",
             :enabled => MarkupRegisterUtils::executable_exists?("perl"))
    register(:bib, "BibTeX", :extensions => ['bib'],
             :enabled => MarkupRegisterUtils::all_gems_available?(["bibtex-ruby", "citeproc-ruby", "csl"]),
             :skip_filters => Proc.new {|filter| true unless [:YAML,:BibTeX,:Sanitize].include?(filter)})
  end
end
