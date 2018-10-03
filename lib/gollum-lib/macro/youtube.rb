module Gollum
  class Macro
    class Youtube < Gollum::Macro

        def render(link)
            "<iframe width=\"560\" height=\"315\" src=\"#{link}\" frameborder=\"0\" allow=\"autoplay; encrypted-media\" allowfullscreen></iframe>"
        end
    end
  end
end
