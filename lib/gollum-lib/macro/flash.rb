module Gollum
  class Macro
    class Flash < Gollum::Macro
      def render(message, type='')
        flash_type = ['warn', 'error', 'success'].include?(type) ? "flash-#{type}" : '' 
        %Q(<div class="flash #{flash_type} my-2">#{message}</div>)
      end
    end
  end
end