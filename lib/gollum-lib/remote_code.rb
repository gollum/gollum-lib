# ~*~ encoding: utf-8 ~*~
require 'net/http'
require 'net/https' # ruby 1.8.7 fix, remove at upgrade
require 'uri'
require 'open-uri'

module Gollum
  class RemoteCode
    def initialize path
      raise(ArgumentError, 'path is nil or empty') if path.nil? or path.empty?
      @uri = URI(path)
    end

    def contents
      @contents ||= req @uri
    end

    private

      def req uri, cut = 1
        return "Too many redirects or retries" if cut >= 10
        http = Net::HTTP.new uri.host, uri.port
        http.use_ssl = true
        resp = http.get uri.path, {
          'Accept'        => 'text/plain',
          'Cache-Control' => 'no-cache',
          'Connection'    => 'keep-alive',
          'User-Agent'    => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0'
        }
        code = resp.code.to_i
        return resp.body if code == 200
        return "Not Found" if code == 404
        return "Unhandled Response Code #{code}" unless code == 304 or not resp.header['location'].nil?
        loc = URI.parse resp.header['location']
        uri2 = loc.relative? ? (uri + loc) : loc # overloads (+)
        req uri2, (cut + 1)
      end
  end
end
