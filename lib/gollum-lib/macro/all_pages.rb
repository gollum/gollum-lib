module Gollum
  class Macro
    class AllPages < Gollum::Macro
      def render
        if @wiki.pages.size > 0
          '<ul id="pages">' + @wiki.pages
          .map { |p| p.path.chomp(::File.extname(p.path)) }
          .map { |p| "<li><a href=#{p}>#{p}</a></li>" }.join + '</ul>'
        end
      end
    end
  end
end
