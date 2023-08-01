module Gollum
  class Macro
    class Icon < Gollum::Macro
      def render(icon)
        %Q(<div class="gollum-icon" data-gollum-icon="#{icon}"></div>)
      end
    end
  end
end