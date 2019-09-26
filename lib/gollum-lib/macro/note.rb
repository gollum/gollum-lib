module Gollum
  class Macro
    class Note < Gollum::Macro
      def render(notice)
        icon = Octicons::Octicon.new('info', {width: 24, height: 24})
        icon.options[:class] << ' mr-2'
        "<div class='flash'>#{icon.to_svg}#{notice}</div>"
      end
    end
  end
end