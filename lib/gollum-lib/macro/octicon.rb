module Gollum
  class Macro
    class Octicon < Gollum::Macro
      def render(symbol, height = nil, width = nil)
        parameters = {}
        parameters[:height] = height if height
        parameters[:width]  = width if width
        "<div>#{Octicons::Octicon.new(symbol, parameters).to_svg}</div>"
      end
    end
  end
end