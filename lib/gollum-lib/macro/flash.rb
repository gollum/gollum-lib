module Gollum
  class Macro
    class Flash < Gollum::Macro
      def render(message, icon='', type='')
        flash_type = ['warn', 'error', 'success'].include?(type) ? "flash-#{type}" : '' 
        flash_icon = icon.empty? ? '' : %Q(data-gollum-icon="#{icon}")
        %Q(<div class="flash #{flash_type} my-2" #{flash_icon}>#{message}</div>)
      end
    end
  end
end