# ~*~ encoding: utf-8 ~*~
module Gollum
    # Represents a Tree (directory) that can be contained in another Tree.
    # We do not really care about any information other than the Tree's path and name:
    # If we want to know a Tree `foo`'s'contents, this can be achieved by e.g. calling wiki.path_list(foo.path)
    class TreeEntry
        attr_reader :sha
        attr_reader :path

        def initialize(sha, path)
            @sha = sha
            @path = path
            @name = ::File.basename(@path)
        end
    end
end