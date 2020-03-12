# ~*~ encoding: utf-8 ~*~
module Gollum
  # Responsible for handling the commit process for a Wiki.  It sets up the
  # Git index, provides methods for modifying the tree, and stores callbacks
  # to be fired after the commit has been made.  This is specifically
  # designed to handle multiple updated pages in a single commit.
  class Committer
    # Gets the instance of the Gollum::Wiki that is being updated.
    attr_reader :wiki

    # Gets a Hash of commit options.
    attr_reader :options

    # Initializes the Committer.
    #
    # wiki    - The Gollum::Wiki instance that is being updated.
    # options - The commit Hash details:
    #           :message   - The String commit message.
    #           :name      - The String author full name.
    #           :email     - The String email address.
    #           :parent    - Optional Gollum::Git::Commit parent to this update.
    #           :tree      - Optional String SHA of the tree to create the
    #                        index from.
    #           :committer - Optional Gollum::Committer instance.  If provided,
    #                        assume that this operation is part of batch of
    #                        updates and the commit happens later.
    #
    # Returns the Committer instance.
    def initialize(wiki, options = {})
      @wiki      = wiki
      @options   = options
      @callbacks = []
    end

    # Public: References the Git index for this commit.
    #
    # Returns a Gollum::Git::Index.
    def index
      @index ||= begin
        idx = @wiki.repo.index
        if (tree = options[:tree])
          idx.read_tree(tree)
        elsif (parent = parents.first)
          idx.read_tree(parent.tree.id)
        end
        idx
      end
    end

    # Public: The committer for this commit.
    #
    # Returns a Gollum::Git::Actor.
    def actor
      @actor ||= begin
        @options[:name]  = @wiki.default_committer_name if @options[:name].nil?
        @options[:email] = @wiki.default_committer_email if @options[:email].nil?
        Gollum::Git::Actor.new(@options[:name], @options[:email])
      end
    end

    # Public: The parent commits to this pending commit.
    #
    # Returns an array of Gollum::Git::Commit instances.
    def parents
      @parents ||= begin
        arr = [@options[:parent] || @wiki.repo.commit(@wiki.ref)]
        arr.flatten!
        arr.compact!
        arr
      end
    end

    # Adds a path to the Index.
    #
    # path   - The String path to be added
    # data   - The String wiki data to store in the tree map.
    #
    # Raises Gollum::DuplicatePageError if a matching filename already exists, unless force_overwrite is explicitly enabled.
    # This way, pages are not inadvertently overwritten.
    #
    # Returns nothing (modifies the Index in place).
    def add_to_index(path, data, options = {}, force_overwrite = false)
      if tree = index.current_tree
        unless page_path_scheduled_for_deletion?(index.tree, path) || force_overwrite
          raise DuplicatePageError.new(path) if tree / path
        end
      end

      unless options[:normalize] == false
        begin
          data = @wiki.normalize(data)
        rescue ArgumentError => err
          # Swallow errors that arise from data being binary
          raise err unless err.message.include?('invalid byte sequence')
        end
      end
      index.add(path, data)
    end

    # Update the given file in the repository's working directory if there
    # is a working directory present.
    #
    # path    - The String path to update
    #
    # Returns nothing.
    def update_working_dir(path)
      unless @wiki.repo.bare
        if @wiki.page_file_dir && !path.start_with?(@wiki.page_file_dir)
          # Skip the path if it is not under the wiki's page file dir
          return nil
        end

        Dir.chdir(::File.join(@wiki.repo.path, '..')) do
          if file_path_scheduled_for_deletion?(index.tree, path)
            @wiki.repo.git.rm(path, :force => true)
          else
            @wiki.repo.git.checkout(path, 'HEAD')
          end
        end
      end
    end

    # Writes the commit to Git and runs the after_commit callbacks.
    #
    # Returns the String SHA1 of the new commit.
    def commit
      sha1 = index.commit(@options[:message], parents, actor, nil, @wiki.ref)
      @callbacks.each do |cb|
        cb.call(self, sha1)
      end
      Hook.execute(:post_commit, self, sha1)
      sha1
    end

    # Adds a callback to be fired after a commit.
    #
    # block - A block that expects this Committer instance and the created
    #         commit's SHA1 as the arguments.
    #
    # Returns nothing.
    def after_commit(&block)
      @callbacks << block
    end

    # Determine if a given page (regardless of format) is scheduled to be
    # deleted in the next commit for the given Index.
    #
    # map   - The Hash map:
    #         key - The String directory or filename.
    #         val - The Hash submap or the String contents of the file.
    # path - The String path of the page file. This may include the format
    #         extension in which case it will be ignored.
    #
    # Returns the Boolean response.
    def page_path_scheduled_for_deletion?(map, path)
      parts = path.split('/')
      if parts.size == 1
        deletions = map.keys.select { |k| !map[k] }
        deletions.any? { |d| d == parts.first }
      else
        part = parts.shift
        if (rest = map[part])
          page_path_scheduled_for_deletion?(rest, parts.join('/'))
        else
          false
        end
      end
    end

    # Determine if a given file is scheduled to be deleted in the next commit
    # for the given Index.
    #
    # map   - The Hash map:
    #         key - The String directory or filename.
    #         val - The Hash submap or the String contents of the file.
    # path - The String path of the file including extension.
    #
    # Returns the Boolean response.
    def file_path_scheduled_for_deletion?(map, path)
      parts = path.split('/')
      if parts.size == 1
        deletions = map.keys.select { |k| !map[k] }
        deletions.any? { |d| d == parts.first }
      else
        part = parts.shift
        if (rest = map[part])
          file_path_scheduled_for_deletion?(rest, parts.join('/'))
        else
          false
        end
      end
    end

    # Proxies methods t
    def method_missing(name, *args)
      index.send(name, *args)
    end
  end
end
