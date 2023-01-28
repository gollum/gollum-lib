module Gollum
  class Macro
    class Warn < Gollum::Macro
      def render(warning)
        %Q(<div class="flash flash-warn" data-gollum-icon="alert">#{warning}</div>)
      end
    end
  end
end