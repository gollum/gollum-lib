module Gollum
  class Macro
    class Video < Gollum::Macro
      def render(fname, auto=false)
        escaped_fname = CGI.escapeHTML(fname)
        properties = auto ? "autoplay='true' playsinline='true' muted='true' loop='true'" : "controls='true'"
        "<video width='100%' height='100%' src='#{escaped_fname}' #{properties}>HTML5 video is not supported on this browser.</video>"
      end
    end
  end
end