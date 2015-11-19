module Gollum
  class Macro
    class SubGlobalTOC < Gollum::Macro
      def render(title = "Sub Global Table of Contents", toc_path = "")
        if @wiki.pages.size > 0
          result = '<ul>' + @wiki.pages.map {|p|
            if p.url_path.match(toc_path)
              "<li><a href=\"#{p.url_path}\">#{p.url_path_display}</a></li>"
            end
	  }.join + '</ul>'
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end
    end
  end
end
