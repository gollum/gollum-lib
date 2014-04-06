module Gollum
  class Cache
    NIL_STRING = "__nil".freeze

    attr_accessor :store

    def initialize
      clear
    end

    def fetch(key, &block)
      value = read(key)
      write(key, value = yield) if block_given? && value.nil?
      value == NIL_STRING ? nil : value
    end

    def clear
      self.store = {}
    end

    def read(key)
      store[key]
    end

    def write(key, value)
      store[key] = value || NIL_STRING
    end
  end
end
