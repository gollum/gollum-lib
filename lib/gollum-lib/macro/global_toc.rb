module Gollum
  class Macro
    class GlobalTOC < Gollum::Macro
      def render(title = "Global Table of Contents")
        if @wiki.pages.size > 0
          prepath = @wiki.base_path.sub(/\/$/, '')
          result  = '<ul>' + @wiki.pages.map { |p| "<li><a href=\"#{CGI::escapeHTML(prepath + "/" + p.escaped_url_path)}\">#{CGI::escapeHTML(p.url_path)}</a></li>" }.join + '</ul>'
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end
    end
  end
end
