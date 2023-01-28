module Gollum
  class Macro
    class Icon < Gollum::Macro
      def render(icon, height = nil, width = nil)
        height = %Q(data-gollum-icon-height="#{height}") if height
        width = %Q(data-gollum-icon-width="#{width}") if width
        %Q(<div class="gollum-icon" #{height} #{width} data-gollum-icon="#{icon}"></div>)
      end
    end
  end
end