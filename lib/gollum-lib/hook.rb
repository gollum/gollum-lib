# ~*~ encoding: utf-8 ~*~
module Gollum
  class Hook
    @hooks = {}

    class << self
      def register(type, id, &block)
        type_hooks     = @hooks[type] ||= {}
        type_hooks[id] = block
      end

      def unregister(type, id)
        type_hooks = @hooks[type]
        if type_hooks
          type_hooks.delete(id)
          @hooks.delete(type) if type_hooks.empty?
        end
      end

      def get(type, id)
        @hooks.fetch(type, {})[id]
      end

      def execute(type, *args)
        type_hooks = @hooks[type]
        if type_hooks
          type_hooks.each_value do |block|
            block.call(*args)
          end
        end
      end
    end

  end
end
