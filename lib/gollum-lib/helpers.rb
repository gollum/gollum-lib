# ~*~ encoding: utf-8 ~*~

module Gollum
  module Helpers
    
    # Replace url-encoded slashes ('%2F') with slashes
    # Clean up double slashes
    def trim_leading_slashes(url)
      return nil if url.nil?
      url.gsub!('%2F', '/')
      Pathname.new(url).cleanpath.to_s
    end
    
    # Take a link path and turn it into a string for display as link text.
    # For example:
    # '/opt/local/bin/ruby.ext' -> 'ruby'
    def path_to_link_text(str)
      return nil unless str
      ::File.basename(str, Page.valid_extension?(str) ? ::File.extname(str) : '')
    end

  end
end
