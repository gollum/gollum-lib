# ~*~ encoding: utf-8 ~*~

module Gollum
  module Helpers
    
    # If url starts with a leading slash, trim down its number of leading slashes to 1. Else, return url unchanged.
    def trim_leading_slashes(url)
      return nil if url.nil?
      url.gsub!('%2F', '/')
      return '/' + url.gsub(/^\/+/, '') if url[0, 1] == '/'
      url
    end
    
    # Take a path and turn it into a string for display as link text.
    # For example:
    # '/opt/local/bin/ruby.ext' -> 'ruby'
    def path_to_link_text(str, is_path = true)
      return str unless str && is_path
      ::File.basename(str, ::File.extname(str))
    end

  end
end
