module Gollum
  class Macro
    class Octicon < Gollum::Macro
      def render(symbol, height = nil, width = nil)
        parameters = {}
        parameters[:height] = height if height
        parameters[:width]  = width if width
        "<div>#{Gollum::Icon.get_icon(symbol, parameters)}</div>"
      end
    end
  end
end