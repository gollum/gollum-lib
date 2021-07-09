module Gollum
  class Macro
    class Warn < Gollum::Macro
      def render(warning)
        icon = Octicons::Octicon.new('alert', {width: 24, height: 24})
        icon.options[:class] << ' mr-2'
        "<div class='flash flash-warn'>#{icon.to_svg}#{CGI::escapeHTML(warning)}</div>"
      end
    end
  end
end