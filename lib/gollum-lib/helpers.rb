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
    
    # Take an absolute path and turn it into a string for display as link text.
    # For example:
    # '/opt/local/bin/ruby.ext' -> 'ruby'
    def abs_path_to_link_text(str)
      return str unless str && str.include?('/')
      ::File.basename(str, ::File.extname(str))
    end

  end
end
