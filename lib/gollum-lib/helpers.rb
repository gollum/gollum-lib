# ~*~ encoding: utf-8 ~*~
module Gollum
  module Helpers

    def trim_leading_slash url
      return url if url.nil?
      url.gsub!('%2F', '/')
      return '/' + url.gsub(/^\/+/, '') if url[0, 1] == '/'
      url
    end

  end
end
