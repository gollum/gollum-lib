# ~*~ encoding: utf-8 ~*~
module Gollum
  class Markup
    
    GitHub::Markup::Markdown::MARKDOWN_GEMS['kramdown'] = proc { |content|
        Kramdown::Document.new(content, :auto_ids => false, :smart_quotes => ["'", "'", '"', '"'].map{|char| char.codepoints.first}).to_html
    }

    register(:markdown,  "Markdown", :regexp => /md|mkdn?|mdown|markdown/)
    register(:textile,   "Textile")
    register(:rdoc,      "RDoc")
    register(:org,       "Org-mode")
    register(:creole,    "Creole", :reverse_links => true)
    register(:rest,      "reStructuredText", :regexp => /re?st(\.txt)?/)
    register(:asciidoc,  "AsciiDoc")
    register(:mediawiki, "MediaWiki", :regexp => /(media)?wiki/, :reverse_links => true)
    register(:pod,       "Pod")
    register(:txt,       "Plain Text")
  end
end