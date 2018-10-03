module Gollum
  class Macro
    class GlobalTOC < Gollum::Macro
      def render(title = "Global Table of Contents", colapse_folder = false, folder_index = "Home")
        if @wiki.pages.size > 0
          included_pages = @wiki.pages.sort_by { |page| page.path }
          included_pages.select! { |page| is_folder_index?(page, folder_index) } unless !colapse_folder

          pagelinks = Hash.new do |hash, key|
            hash[key] = Array.new
          end

          included_pages.map do |p|
              href = ::File.join(@wiki.base_path, p.url_path)
              dirname = ::File.dirname(p.url_path_display)
              basename = ::File.basename(p.url_path_display)
              if (is_folder_index?(p, folder_index) && dirname != ".") then
                  pagelinks[dirname].unshift("<a href=\"#{href}\">#{dirname}</a>")
              else
                  pagelinks[dirname].push("<a href=\"#{href}\">#{basename}</a>")
              end
          end

          result = ""
          pagelinks.keys.sort.each do |dirname|
              links = pagelinks[dirname]
              result += "<div class=\"toc-dir\">#{links[0]}</div><ul>"
              first = true
              links.each do |link|
                  if first then
                      first = false
                  else
                      result += "<li>#{link}</li>"
                  end
              end
              result += '</ul>'
          end
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end
    end

    private

    def is_folder_index?(page, folder_index)
        return ::File.basename(page.path, ".*") == folder_index
    end
  end
end
