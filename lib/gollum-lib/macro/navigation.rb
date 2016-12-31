module Gollum
  class Macro
    class Navigation < Gollum::Macro

      def render(title = "Navigate in the TOC", toc_root_path = "", full_path = false)
        my_page = @page.sub_page ? @page.parent_page : @page;

        if toc_root_path == "" then
          toc_root_path = ::File.dirname(my_page.path)
        end

        title.sub! "%%" do
            Gollum::Page.url_path_to_display(::File.basename(toc_root_path))
        end

        if @wiki.pages.size > 0
          list_items = @wiki.pages.map do |page|
            if page.url_path.start_with?(toc_root_path)
              path_display = full_path ? page.url_path_display  : page.url_path_display.sub(toc_root_path,"").sub(/^\//,'')
              path_display = format(path_display)

              if page.path != my_page.path then
                  "<li><a href=\"#{::File.join(page.wiki.base_path, page.url_path)}\">#{path_display}</a></li>"
              else
                  "<li class=\"current_page\">#{path_display}</li>"
              end
            end
          end
          result = "<ul>#{list_items.join}</ul>"
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end

    end
  end
end
