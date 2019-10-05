require 'yaml'

REDIRECTS_FILE = '.redirects.gollum'

module Gollum
  
  class Redirects
        
    def self.load(wiki)
      file = wiki.file(REDIRECTS_FILE)
      redirects = {}
      if file
        begin
          redirects = YAML.load(file.raw_data)
        rescue YAML::Error
          # TODO handle error
        end
      end
      redirects
    end
    
    def self.dump(wiki, hash)
      wiki.overwrite_file(REDIRECTS_FILE, hash.to_yaml, {})
    end
    
  end # Class
  
end # Module