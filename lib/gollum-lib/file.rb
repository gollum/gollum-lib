# ~*~ encoding: utf-8 ~*~
require 'pathname'

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
      @blob = nil
      @path = nil
      @on_disk = false
      @on_disk_path = nil
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
      return @path if on_disk?
      @blob && @blob.name
    end
    alias filename name

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

    # Public: Is this an on-disk file reference?
    #
    # Returns true if this is a pointer to an on-disk file
    def on_disk?
      return @on_disk
    end

    # Public: The path to this file on disk
    #
    # Returns nil if on_disk? is false.
    def on_disk_path
      return @on_disk_path
    end

    # Public: The Grit::Commit version of the file.
    attr_accessor :version

    # Public: The String path of the file.
    attr_reader :path

    # Public: The String mime type of the file.
    def mime_type
      @blob && @blob.mime_type
    end

    # Populate the File with information from the Blob.
    #
    # blob - The Grit::Blob that contains the info.
    # path - The String directory path of the file.
    #
    # Returns the populated Gollum::File.
    def populate(blob, path=nil)
      @blob = blob
      @path = "#{path}/#{blob.name}"[1..-1]
      @on_disk = false
      @on_disk_path = nil
      self
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
        source = ::File.readlink(pathname.to_path)
        realpath = ::File.join(::File.dirname(pathname.to_path), source)
        return false unless realpath && ::File.exist?(realpath)
        @on_disk_path = realpath.to_s
      else
        @on_disk_path = pathname.to_path
      end
      return true
    end

    # Find a file in the given Gollum repo.
    #
    # name    - The full String path.
    # version - The String version ID to find.
    # try_on_disk - If true, try to return just a reference to a file
    #               that exists on the disk.
    #
    # Returns a Gollum::File or nil if the file could not be found. Note
    # that if you specify try_on_disk=true, you may or may not get a file
    # for which on_disk? is actually true.
    def find(name, version, try_on_disk=false)
      checked = name.downcase
      map     = @wiki.tree_map_for(version)
      commit  = version.is_a?(Grit::Commit) ? version : @wiki.commit_for(version)

      if entry = map.detect { |entry| entry.path.downcase == checked }
        @path    = name
        @version = commit

        if try_on_disk && get_disk_reference(name, commit)
          @on_disk = true
        else
          @blob = entry.blob(@wiki.repo)
        end

        self
      end
    end
  end
end
