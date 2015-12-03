module Gollum
  class Macro
    class Navigation < Gollum::Macro

      def render(title = "Navigate in the TOC", toc_root_path = ::File.dirname(@page.path), full_path = false)
        if @wiki.pages.size > 0
          list_items = @wiki.pages.map do |page|
            if page.url_path.start_with?(toc_root_path)
              path_display = full_path ? page.url_path_display  : page.url_path_display.sub(toc_root_path,"").sub(/^\//,'')
              "<li><a href=\"/#{page.url_path}\">#{path_display}</a></li>"
            end
          end
          result = "<ul>#{list_items.join}</ul>"
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end

    end
  end
end
