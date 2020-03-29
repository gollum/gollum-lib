require 'yaml'

REDIRECTS_FILE = '.redirects.gollum'

module Gollum
  
  module Redirects
        
    def stale?
      @current_head != @wiki.repo.head.commit.sha
    end

    def init(wiki)
      @wiki = wiki
      @current_head = @wiki.repo.head.commit.sha
    end

    def load
      file = @wiki.file(REDIRECTS_FILE)
      redirects = {}
      if file
        begin
          redirects = YAML.load(file.raw_data)
        rescue YAML::Error
          # TODO handle error
        end
      end
      self.clear
      self.merge!(redirects)
    end
    
    def dump
      @wiki.overwrite_file(REDIRECTS_FILE, self.to_yaml, {})
    end
    
  end # Redirects Module

end # Gollum Module
