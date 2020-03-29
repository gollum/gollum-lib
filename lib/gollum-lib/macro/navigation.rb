module Gollum
  class Macro
    class Navigation < Gollum::Macro

      def render(title = "Navigate this directory", toc_root_path = ::File.dirname(@page.url_path), full_path = false)
        pages = @wiki.pages
        if pages.size > 0
          prepath=@wiki.base_path.sub(/\/$/, '')
          list_items = pages.map do |page|
            if toc_root_path == '.' || page.url_path =~ /^#{toc_root_path}\//
              path_display = (full_path || toc_root_path == '.') ? page.url_path  : page.url_path.sub(/^#{toc_root_path}\//,"").sub(/^\//,'')
              "<li><a href=\"#{prepath}/#{page.escaped_url_path}\">#{path_display}</a></li>"
            end
          end
          result = "<ul>#{list_items.join}</ul>"
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end

    end
  end
end
