# ~*~ encoding: utf-8 ~*~
module Gollum
  class File
    Wiki.file_class = self

    # Public: Initialize a file.
    #
    # wiki - The Gollum::Wiki in question.
    #
    # Returns a newly initialized Gollum::File.
    def initialize(wiki)
      @wiki = wiki
      @blob_entry = nil
      @path = nil
    end

    # Public: The url path required to reach this page within the repo.
    #
    # Returns the String url_path
    def url_path
      path = self.path
      path = path.sub(/\/[^\/]+$/, '/') if path.include?('/')
      path
    end

    # Public: The url_path, but CGI escaped.
    #
    # Returns the String url_path
    def escaped_url_path
      CGI.escape(self.url_path).gsub('%2F','/')
    end

    # Public: The on-disk filename of the file.
    #
    # Returns the String name.
    def name
      @path && ::File.basename(@path)
    end
    alias filename name

    # Public: The raw contents of the page.
    #
    # Returns the String data.
    def raw_data
      return nil unless @blob_entry

      if !@wiki.repo.bare? && @blob_entry.mode == 40960
        new_path = @blob_entry.symlink_target(::File.join(@wiki.repo.path, '..', self.path))
        return IO.read(new_path) if new_path
      end

      @blob_entry.blob(@wiki.repo).read_raw.data
    end

    # Public: The Rugged::Commit version of the file.
    attr_accessor :version

    # Public: The String path of the file.
    attr_reader :path

    # Public: The String mime type of the file.
    def mime_type
      @blob_entry.mime_type
    end

    # Populate the File with information from the Blob.
    #
    # blob - The Gollum::BlobEntry that contains the info.
    # path - The String directory path of the file.
    #
    # Returns the populated Gollum::File.
    def populate(blob_entry, path=nil)
      @blob_entry = blob_entry
      @path = "#{path}/#{blob_entry.name}"[1..-1]
      self
    end

    #########################################################################
    #
    # Internal Methods
    #
    #########################################################################

    # Find a file in the given Gollum repo.
    #
    # name    - The full String path.
    # version - The String version ID to find.
    #
    # Returns a Gollum::File or nil if the file could not be found.
    def find(name, version)
      checked = name.downcase
      map     = @wiki.tree_map_for(version)
      if entry = map.detect { |entry| entry.path.downcase == checked }
        @path    = name
        @blob_entry    = entry
        @version = version.is_a?(Rugged::Commit) ? version : @wiki.commit_for(version)
        self
      end
    end
  end
end
