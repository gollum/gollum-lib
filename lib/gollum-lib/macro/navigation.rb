module Gollum
  class Macro
    class Navigation < Gollum::Macro
      def render(title = "Navigate in the TOC", toc_root_path = "")
        if @wiki.pages.size > 0
          result = '<ul>' + @wiki.pages.map {|p|
            if p.url_path.match(toc_root_path)
              "<li><a href=\"#{p.url_path}\">#{p.url_path_display}</a></li>"
            end
	  }.join + '</ul>'
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end
    end
  end
end
