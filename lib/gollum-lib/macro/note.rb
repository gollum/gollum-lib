module Gollum
  class Macro
    class Note < Gollum::Macro
      def render(notice)
        %Q(<div class="flash gollum-note my-2">#{notice}</div>)
      end
    end
  end
end