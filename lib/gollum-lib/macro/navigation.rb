module Gollum
  class Macro
    class Navigation < Gollum::Macro
      def render(title = "Navigate in the TOC", toc_root_path = File.dirname(@page.path), full_path = false)
        if @wiki.pages.size > 0
          result = '<ul>' + @wiki.pages.map {|p|
            if p.url_path.start_with?(toc_root_path)
	      path_display = full_path ? p.url_path_display  : p.url_path_display.sub(toc_root_path,"").sub(/^\//,'')
              "<li><a href=\"/#{p.url_path}\">#{path_display}</a></li>"
            end
	  }.join + '</ul>'
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end
    end
  end
end
