# ~*~ encoding: utf-8 ~*~
module Gollum
  # Controls all access to the Git objects from Gollum.  Extend this class to
  # add custom caching for special cases.
  class GitAccess
    # Initializes the GitAccess instance.
    #
    # path          - The String path to the Git repository that holds the
    #                 Gollum site.
    # page_file_dir - String the directory in which all page files reside
    #
    # Returns this instance.
    def initialize(path, page_file_dir = nil, bare = nil)
      @page_file_dir = page_file_dir
      @path          = path
      @repo = Gollum::Git::Repo.new(path, { :is_bare => bare })
      clear
    end

    # Public: Determines whether the Git repository exists on disk.
    #
    # Returns true if it exists, or false.
    def exist?
      @repo.git.exist?
    end

    # Public: Converts a given Git reference to a SHA, using the cache if
    # available.
    #
    # ref - a String Git reference (ex: "master")
    #
    # Returns a String, or nil if the ref isn't found.
    def ref_to_sha(ref)
      ref = ref.to_s
      return if ref.empty?
      sha =
          if sha?(ref)
            ref
          else
            get_cache(:ref, ref) { ref_to_sha!(ref) }
          end.to_s
      sha.empty? ? nil : sha
    end

    # Public: Gets a recursive list of Git blobs for the whole tree at the
    # given commit.
    #
    # ref - A String Git reference or Git SHA to a commit.
    #
    # Returns an Array of BlobEntry instances.
    def tree(ref)
      if (sha = ref_to_sha(ref))
        get_cache(:tree, sha) { tree!(sha) }
      else
        []
      end
    end

    # Public: Fetches the contents of the Git blob at the given SHA.
    #
    # sha - A String Git SHA.
    #
    # Returns the String content of the blob.
    def blob(sha)
      cat_file!(sha)
    end

    # Public: Looks up the Git commit using the given Git SHA or ref.
    #
    # ref - A String Git SHA or ref.
    #
    # Returns a Gollum::Git::Commit.
    def commit(ref)
      if sha?(ref)
        get_cache(:commit, ref) { commit!(ref) }
      else
        if (sha = get_cache(:ref, ref))
          commit(sha)
        else
          if (cm = commit!(ref))
            set_cache(:ref, ref, cm.id)
            set_cache(:commit, cm.id, cm)
          end
        end
      end
    end

    # Public: Clears all of the cached data that this GitAccess is tracking.
    #
    # Returns nothing.
    def clear
      @ref_map    = {}
      @tree_map   = {}
      @commit_map = {}
    end

    # Public: Refreshes just the cached Git reference data.  This should
    # be called after every Gollum update.
    #
    # Returns nothing.
    def refresh
      @ref_map.clear
    end

    #########################################################################
    #
    # Internal Methods
    #
    #########################################################################

    # Gets the String path to the Git repository.
    attr_reader :path

    # Gets the Gollum::Git::Repo instance for the Git repository.
    attr_reader :repo

    # Gets a Hash cache of refs to commit SHAs.
    #
    #   {"master" => "abc123", ...}
    #
    attr_reader :ref_map

    # Gets a Hash cache of commit SHAs to a recursive tree of blobs.
    #
    #   {"abc123" => [<BlobEntry>, <BlobEntry>]}
    #
    attr_reader :tree_map

    # Gets a Hash cache of commit SHAs to the Gollum::Git::Commit instance.
    #
    #     {"abcd123" => <Gollum::Git::Commit>}
    #
    attr_reader :commit_map

    # Checks to see if the given String is a 40 character hex SHA.
    #
    # str - Possible String SHA.
    #
    # Returns true if the String is a SHA, or false.
    def sha?(str)
      !!(str =~ /^[0-9a-f]{40}$/)
    end

    # Looks up the Git SHA for the given Git ref.
    #
    # ref - String Git ref.
    #
    # Returns a String SHA.
    def ref_to_sha!(ref)
      commit = @repo.commit(ref)
      commit ? commit.id : nil
    end

    # Looks up the Git blobs for a given commit.
    #
    # sha - String commit SHA.
    #
    # Returns an Array of BlobEntry instances.
    def tree!(sha)
      tree  = @repo.lstree(sha, { :recursive => true })
      items = []
      tree.each do |entry|
        if entry[:type] == 'blob'
          next if @page_file_dir && !entry[:path].start_with?("#{@page_file_dir}/")
          items << BlobEntry.new(entry[:sha], entry[:path], entry[:size], entry[:mode])
        end
      end
      items
    end

    # Reads the content from the Git db at the given SHA.
    #
    # sha - The String SHA.
    #
    # Returns the String content of the Git object.
    def cat_file!(sha)
      @repo.git.cat_file({ :p => true }, sha)
    end

    # Reads a Git commit.
    #
    # sha - The string SHA of the Git commit.
    #
    # Returns a Gollum::Git::Commit.
    def commit!(sha)
      @repo.commit(sha)
    end

    # Attempts to get the given data from a cache.  If it doesn't exist, it'll
    # pass the results of the yielded block to the cache for future accesses.
    #
    # name - The cache prefix used in building the full cache key.
    # key  - The unique cache key suffix, usually a String Git SHA.
    #
    # Yields a block to pass to the cache.
    # Returns the cached result.
    def get_cache(name, key)
      cache = instance_variable_get("@#{name}_map")
      value = cache[key]
      if value.nil? && block_given?
        set_cache(name, key, value = yield)
      end
      value == :_nil ? nil : value
    end

    # Writes some data to the internal cache.
    #
    # name  - The cache prefix used in building the full cache key.
    # key   - The unique cache key suffix, usually a String Git SHA.
    # value - The value to write to the cache.
    #
    # Returns nothing.
    def set_cache(name, key, value)
      cache      = instance_variable_get("@#{name}_map")
      cache[key] = value || :_nil
    end
  end
end
