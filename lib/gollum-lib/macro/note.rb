module Gollum
  class Macro
    class Note < Gollum::Macro
      def render(notice, octicon = 'info')
        icon = ""
        defaults = {width: 24, height: 24, class: 'mr-2'}
        unless octicon.empty?
          begin
            icon = Gollum::Icon.get_icon(octicon, defaults)
          rescue RuntimeError
            icon = Gollum::Icon.get_icon('info', defaults)
          end
        end
        "<div class='flash my-2'>#{icon}#{notice}</div>"
      end
    end
  end
end