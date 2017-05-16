module Gollum
  class Macro
    class Video < Gollum::Macro
      def render (fname)
        "<video width=\"100%\" height=\"100%\" src=\"#{fname}\" controls> HTML5 video is not supported on this Browser.</video>"
      end
    end
  end
end