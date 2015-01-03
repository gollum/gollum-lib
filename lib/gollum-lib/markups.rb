# ~*~ encoding: utf-8 ~*~
module Gollum
  class Markup
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