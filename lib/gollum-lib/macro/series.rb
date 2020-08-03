module Gollum
  class Macro

    class Series < Gollum::Macro
      def render(series_prefix = "")
      	raise "This page's name does not match the prefix '#{series_prefix}'" unless active_page.name =~ /^#{series_prefix}/
      	render_links(*find_series(series_prefix))
      end

      def render_links(previous_page, next_page)
      	result = "Previous: <a href=\"#{::File.join(@wiki.base_path,previous_page.escaped_url_path)}\">#{previous_page.name}</a>" if previous_page
      	result = "#{result}#{result ? ' | ' : ''}Next: <a href=\"#{::File.join(@wiki.base_path,next_page.escaped_url_path)}\">#{next_page.name}</a>" if next_page
      	wrap_result(result)
      end

      def wrap_result(result)
      	result.nil? ? "" : "<div class=\"series\">#{result}</div>"
      end

      def find_series(series_prefix = "")
      	dir = @wiki.pages.select {|page| ::File.dirname(page.path) == ::File.dirname(@page.path)}
      	dir.select! {|page| page.name =~ /\A#{series_prefix}/ } unless series_prefix.empty?
      	dir.sort_by! {|page| page.name}
      	self_index = dir.find_index {|page| page.name == active_page.name}
      	if self_index > 0
          return dir[self_index-1], dir[self_index+1]
      	else
          return nil, dir[self_index+1]
      	end
      end
    end

    class SeriesStart < Gollum::Macro::Series
      def render_links(previous_page, next_page)
        result = "Next: <a href=\"#{::File.join(@wiki.base_path,next_page.escaped_url_path)}\">#{next_page.name}</a>" if next_page
        wrap_result(result)
      end
    end

    class SeriesEnd < Gollum::Macro::Series
      def render_links(previous_page, next_page)
        result = "Previous: <a href=\"#{::File.join(@wiki.base_path,previous_page.escaped_url_path)}\">#{previous_page.name}</a>" if previous_page
        wrap_result(result)
      end
    end

  end
end