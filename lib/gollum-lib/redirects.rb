require 'yaml'

REDIRECTS_FILE = '.redirects.gollum'

module Gollum
  
  module Redirects
        
    def stale?
      @current_head != get_head_sha
    end

    def init(wiki)
      @wiki = wiki
      @current_head = get_head_sha
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

    def dump(commit=nil)
      commit = {} if commit.nil?
      @wiki.overwrite_file(REDIRECTS_FILE, self.to_yaml, commit)
    end
    
    def get_head_sha
      @wiki.repo.head ? @wiki.repo.head.commit.sha : nil
    end
    
  end # Redirects Module

end # Gollum Module
