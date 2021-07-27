module Gollum
  class Macro
    class Note < Gollum::Macro
      def render(notice, octicon = 'info')
        icon = ""
        unless octicon.empty?
          begin
            icon = Octicons::Octicon.new(octicon, {width: 24, height: 24})
          rescue RuntimeError
            icon = Octicons::Octicon.new('info', {width: 24, height: 24})
          end
          icon.options[:class] << ' mr-2'
          icon = icon.to_svg
        end
        "<div class='flash'>#{icon}#{notice}</div>"
      end
    end
  end
end