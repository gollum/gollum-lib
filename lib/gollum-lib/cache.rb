module Gollum
  class Cache
    attr_accessor :store

    def initialize
      clear
    end

    def fetch(key, &block)
      value = read(key)
      write(key, value = yield) if block_given? && value.nil? && !store.has_key?(key)
      value
    end

    def clear
      self.store = {}
    end

    def read(key)
      store[key]
    end

    def write(key, value)
      store[key] = value
    end
  end
end
