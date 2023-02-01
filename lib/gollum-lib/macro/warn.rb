module Gollum
  class Macro
    class Warn < Gollum::Macro
      def render(warning)
        %Q(<div class="flash flash-warn gollum-warning my-2">#{warning}</div>)
      end
    end
  end
end