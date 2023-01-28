module Gollum
  class Macro
    class Note < Gollum::Macro
      def render(notice, icon = 'info')
        %Q(<div class="flash" data-gollum-icon="#{icon}">#{notice}</div>)
      end
    end
  end
end