# ~*~ encoding: utf-8 ~*~

module Gollum
  class File

    # Find a file in the given Gollum wiki.
    #
    # wiki    - The wiki.
    # path    - The full String path.
    # version - The String version ID to find.
    # try_on_disk - If true, try to return just a reference to a file
    #               that exists on the disk.
    #
    # Returns a Gollum::File or nil if the file could not be found. Note
    # that if you specify try_on_disk=true, you may or may not get a file
    # for which on_disk? is actually true.
    def self.find(wiki, path, version, try_on_disk = false)
      map = wiki.tree_map_for(version.to_s)

      if wiki.page_file_dir
       query_path = ::File.join(wiki.page_file_dir, path)
      else
       query_path = path
      end

      begin
        entry = map.detect do |entry|
          path_match(::File.join('/', query_path), entry)
        end
      rescue Gollum::Git::NoSuchShaFound
        return nil
      end

      if entry
        result = self.new(wiki)
        result.populate(entry.blob(wiki.repo), entry.dir)
        result.version = version.is_a?(Gollum::Git::Commit) ? version : wiki.commit_for(version)
        result.get_disk_reference(query_path, result.version) if try_on_disk
        result
      else
        nil
      end
    end

    # Returns true if the given query corresponds to the in-repo path of the BlobEntry.
    #
    # query     - The string path to match.
    # entry     - The BlobEntry to check against.
    def self.path_match(query, entry)
      query == ::File.join('/', entry.path)
    end
    
    # Public: Initialize a file.
    #
    # wiki - The Gollum::Wiki in question.
    #
    # Returns a newly initialized Gollum::File.
    def initialize(wiki)
      @wiki         = wiki
      @blob         = nil
      @path         = nil
      @on_disk      = false
      @on_disk_path = nil
    end

    # Public: The path of the page within the repo.
    #
    # Returns the String path.
    attr_reader :path

    # Public: The Gollum::Git::Commit version of the file.
    attr_accessor :version

    # Public: Whether the file can be read from disk.
    attr_accessor :on_disk

    # Public: The SHA hash identifying this page
    #
    # Returns the String SHA.
    def sha
      @blob && @blob.id
    end

    # Public: The on-disk filename of the page including extension.
    #
    # Returns the String name.
    def filename
      @blob && @blob.name
    end
    alias :name :filename

    # Public: The url path required to reach this page within the repo.
    #
    # Returns the String url_path
    def url_path
      construct_path(filename)
    end

    # Public: The url_path, but URL encoded.
    #
    # Returns the String url_path
    def escaped_url_path
      ERB::Util.url_encode(self.url_path).gsub('%2F', '/').force_encoding('utf-8')
    end

    # Public: The raw contents of the page.
    #
    # Returns the String data.
    def raw_data
      return IO.read(@on_disk_path) if on_disk?
      return nil unless @blob

      if !@wiki.repo.bare && @blob.is_symlink
        new_path = @blob.symlink_target(::File.join(@wiki.repo.path, '..', self.path))
        return IO.read(new_path) if new_path
      end

      @blob.data
    end

    # Populate the File with information from the Blob.
    #
    # blob - The Gollum::Git::Blob that contains the info.
    # path - The String directory path of the file.
    #
    # Returns the populated Gollum::File.
    def populate(blob, path = nil)
      @blob         = blob
      @path         = "#{path}#{::File::SEPARATOR}#{blob.name}"[1..-1]
      @on_disk      = false
      @on_disk_path = nil
      self
    end

    # Public: Is this an on-disk file reference?
    #
    # Returns true if this is a pointer to an on-disk file
    def on_disk?
      @on_disk
    end

    # Public: The path to this file on disk
    #
    # Returns nil if on_disk? is false.
    def on_disk_path
      @on_disk_path
    end

    # Public: The String mime type of the file.
    def mime_type
      @blob && @blob.mime_type
    end

    #########################################################################
    #
    # Internal Methods
    #
    #########################################################################

    # Return the file path to this file on disk, if available.
    #
    # Returns nil if the file isn't available on disk. This can occur if the
    # repo is bare, if the commit isn't the HEAD, or if there are problems
    # resolving symbolic links.
    def get_disk_reference(name, commit)
      return false if @wiki.repo.bare
      return false if commit.sha != @wiki.repo.head.commit.sha

      # This will try to resolve symbolic links, as well
      pathname = Pathname.new(::File.expand_path(::File.join(@wiki.repo.path, '..', name)))
      if pathname.symlink?
        source   = ::File.readlink(pathname.to_path)
        realpath = ::File.join(::File.dirname(pathname.to_path), source)
        return false unless realpath && ::File.exist?(realpath)
        @on_disk_path = realpath.to_s
      else
        @on_disk_path = pathname.to_path
      end
      @on_disk = true
    end

    private

    def construct_path(name)
      path = if self.path.include?('/')
        self.path.sub(/\/[^\/]+$/, '/')
          else
            ''
          end
      path = path[@wiki.page_file_dir.length+1..-1] if @wiki.page_file_dir # Chop off the page file dir plus the first slash if necessary 
      path << name
    end

  end
end
