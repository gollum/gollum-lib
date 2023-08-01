module Gollum
  class Macro
    class Video < Gollum::Macro
      def render (fname)
        "<video width=\"100%\" height=\"100%\" src=\"#{CGI::escapeHTML(fname)}\" controls=\"true\"> HTML5 video is not supported on this Browser.</video>"
      end
    end
  end
end