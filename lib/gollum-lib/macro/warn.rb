module Gollum
  class Macro
    class Warn < Gollum::Macro
      def render(warning)
        icon = Gollum::Icon.get_icon('alert', {width: 24, height: 24, class: 'mr-2'})
        "<div class='flash flash-warn my-2'>#{icon}#{warning}</div>"
      end
    end
  end
end