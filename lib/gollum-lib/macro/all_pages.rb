module Gollum
  class Macro
    class AllPages < Gollum::Macro
      def render
        if @wiki.pages.size > 0
          '<ul id="pages">' + @wiki.pages.map { |p| "<li>#{p.name}</li>" }.join + '</ul>'
        end
      end
    end
  end
end
