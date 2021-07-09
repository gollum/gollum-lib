module Gollum
  class Macro
    class Audio < Gollum::Macro
      def render (fname)
        "<audio width=\"100%\" height=\"100%\" src=\"#{CGI::escapeHTML(fname)}\" controls=\"\"> HTML5 audio is not supported on this Browser.</audio>"
      end
    end
  end
end