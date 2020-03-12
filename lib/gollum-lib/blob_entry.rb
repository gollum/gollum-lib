# ~*~ encoding: utf-8 ~*~
module Gollum
  class BlobEntry
    # Gets the String SHA for this blob.
    attr_reader :sha

    # Gets the full path String for this blob.
    attr_reader :path

    # Gets the Fixnum size of this blob.
    attr_reader :size

    # Gets the Fixnum mode of this blob.
    attr_reader :mode

    def initialize(sha, path, size = nil, mode = nil)
      @sha  = sha
      @path = path
      @size = size
      @mode = mode
      @dir  = @name = @blob = nil
    end

    # Gets the normalized directory path String for this blob.
    def dir
      @dir ||= self.class.normalize_dir(::File.dirname(@path))
    end

    # Gets the file base name String for this blob.
    def name
      @name ||= ::File.basename(@path)
    end

    # Gets a Gollum::Git::Blob instance for this blob.
    #
    # repo - Gollum::Git::Repo instance for the Gollum::Git::Blob.
    #
    # Returns an unbaked Gollum::Git::Blob instance.
    def blob(repo)
      @blob ||= Gollum::Git::Blob.create(repo,
                                  :id => @sha, :name => name, :size => @size, :mode => @mode)
    end

    # Gets a Page instance for this blob.
    #
    # wiki - Gollum::Wiki instance for the Gollum::Page
    #
    # Returns a Gollum::Page instance.
    def page(wiki, commit)
      ::Gollum::Page.new(wiki, self.blob(wiki.repo), self.dir, commit)
    end

    # Gets a File instance for this blob.
    #
    # wiki - Gollum::Wiki instance for the Gollum::File
    #
    # Returns a Gollum::File instance.
    def file(wiki, commit)
      ::Gollum::File.new(wiki, self.blob(wiki.repo), self.dir, commit)
    end

    def inspect
      %(#<Gollum::BlobEntry #{@sha} #{@path}>)
    end

    # Normalizes a given directory name for searching through tree paths.
    # Ensures that a directory begins with a slash, or
    #
    #   normalize_dir("")      # => ""
    #   normalize_dir(".")     # => ""
    #   normalize_dir("foo")   # => "/foo"
    #   normalize_dir("/foo/") # => "/foo"
    #   normalize_dir("/")     # => ""
    #   normalize_dir("c:/")   # => ""
    #
    # dir - String directory name.
    #
    # Returns a normalized String directory name, or nil if no directory
    # is given.
    def self.normalize_dir(dir)
      return '' if dir =~ /^.:\/$/
      if dir
        dir = ::File.expand_path(dir, '/')
        dir = dir[2..-1] if dir =~ /^[a-zA-Z]:\// # expand_path may add d:/ on windows
        dir = '' if dir == '/'
      end
      dir
    end
  end
end
