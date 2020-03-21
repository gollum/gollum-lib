# ~*~ encoding: utf-8 ~*~

module Gollum
  class File

    # Does the filesystem support reading symlinks?
    FS_SUPPORT_SYMLINKS = !Gem.win_platform?

    class << self

      # For use with self.find: returns true if the given query corresponds to the in-repo path of the BlobEntry.
      #
      # query     - The String path to match.
      # entry     - The BlobEntry to check against.
      def path_match(query, entry, global_match = false)
        query == ::File.join('/', entry.path)
      end
    end

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
    def self.find(wiki, path, version, try_on_disk = false, global_match = false)
      map = wiki.tree_map_for(version.to_s)

      query_path = Pathname.new(::File.join(['/', wiki.page_file_dir, path].compact)).cleanpath.to_s
      query_path.sub!(/^\/\//, '/') if Gem.win_platform? # On Windows, Pathname#cleanpath will leave double slashes at the start of a path intact, so sub them out.

      begin
        entry = map.detect do |entry|
          path_match(query_path, entry, global_match)
        end
        entry ? self.new(wiki, entry.blob(wiki.repo), entry.dir, version, try_on_disk) : nil
      rescue Gollum::Git::NoSuchShaFound
        nil
      end
    end

    # Public: Initialize a file.
    #
    # wiki - The Gollum::Wiki
    # blob - The Gollum::Git::Blob
    # path - The String path
    # version - The String SHA or Gollum::Git::Commit version
    # try_on_disk - If true, try to get an on disk reference for this file.
    #
    # Returns a newly initialized Gollum::File.
    def initialize(wiki, blob, path, version, try_on_disk = false)
      @wiki         = wiki
      @blob         = blob
      @path         = "#{path}/#{blob.name}"[1..-1]
      @version      = version.is_a?(Gollum::Git::Commit) ? version : @wiki.commit_for(version)
      get_disk_reference if try_on_disk
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

    # Public: The url path required to reach this file within the repo.
    #
    # Returns the String url_path
    def url_path
      # Chop off the page_file_dir and first slash if necessary
      @wiki.page_file_dir ? self.path[@wiki.page_file_dir.length+1..-1] : self.path
    end

    # Public: The url_path, but URL encoded.
    #
    # Returns the String url_path
    def escaped_url_path
      ERB::Util.url_encode(self.url_path).gsub('%2F', '/').force_encoding('utf-8')
    end

    # Public: The raw contents of the file.
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

    # Public: Is this an on-disk file reference?
    #
    # Returns true if this is a pointer to an on-disk file
    def on_disk?
      !!@on_disk
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

    def self.protected_files
      ['custom.css', 'custom.js', '.redirects.gollum']
    end

    private

    # Return the file path to this file on disk, if available.
    #
    # Returns nil if the file isn't available on disk. This can occur if the
    # repo is bare, if the commit isn't the HEAD, or if there are problems
    # resolving symbolic links.
    def get_disk_reference
      return false if @wiki.repo.bare
      return false if @version.sha != @wiki.repo.head.commit.sha
      return false if @blob.is_symlink && !FS_SUPPORT_SYMLINKS

      # This will try to resolve symbolic links, as well
      pathname = Pathname.new(::File.expand_path(::File.join(@wiki.repo.path, '..', @path)))
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

  end
end
