# ~*~ encoding: utf-8 ~*~
require 'pathname'

module Gollum
  class Wiki
    include Pagination

    class << self
      # Sets the default ref for the wiki.
      attr_writer :default_ref

      # Sets the default name for commits.
      attr_writer :default_committer_name

      # Sets the default email for commits.
      attr_writer :default_committer_email

      # Hash for setting different default wiki options
      # These defaults can be overridden by options passed directly to initialize()
      attr_writer :default_options

      def default_ref
        @default_ref || 'master'
      end

      def default_committer_name
        @default_committer_name || 'Anonymous'
      end

      def default_committer_email
        @default_committer_email || 'anon@anon.com'
      end

      def default_options
        @default_options || {}
      end
    end

    # Whether or not the wiki's repository is bare (doesn't have a working directory)
    attr_reader :repo_is_bare

    # The String path to the repository
    attr_reader :path

    # The String base path to prefix to internal links. For example, when set
    # to "/wiki", the page "Hobbit" will be linked as "/wiki/Hobbit". Defaults
    # to "/".
    attr_reader :base_path

    # Gets the String ref in which all page files reside.
    attr_reader :ref

    # Gets the String directory in which all page files reside.
    attr_reader :page_file_dir

    # Injects custom css from custom.css in root repo.
    # Defaults to false
    attr_reader :css

    # Sets page title to value of first h1
    # Defaults to false
    attr_reader :h1_title

    # Whether or not to render a page's metadata on the page
    # Defaults to true
    attr_reader :display_metadata

    # Gets the custom index page for / and subdirs (e.g. foo/)
    attr_reader :index_page

    # Gets side on which the sidebar should be shown
    attr_reader :bar_side

    # An array of symbols which refer to classes under Gollum::Filter,
    # each of which is an element in the "filtering chain".  See
    # the documentation for Gollum::Filter for more on how this chain
    # works, and what filter classes need to implement.
    attr_reader :filter_chain

    # Global metadata to be merged into the metadata for each page
    attr_reader :metadata

    # Public: Initialize a new Gollum Repo.
    #
    # path    - The String path to the Git repository that holds the Gollum
    #           site.
    # options - Optional Hash:
    #           :universal_toc - Table of contents on all pages.  Default: false
    #           :base_path     - String base path for all Wiki links.
    #                            Default: "/"
    #           :page_file_dir - String the directory in which all page files reside
    #           :ref - String the repository ref to retrieve pages from
    #           :mathjax       - Set to false to disable mathjax.
    #           :user_icons    - Enable user icons on the history page. [gravatar, identicon, none].
    #                            Default: none
    #           :show_all      - Show all files in file view, not just valid pages.
    #                            Default: false
    #           :css           - Include the custom.css file from the repo.
    #           :emoji         - Parse and interpret emoji tags (e.g. :heart:).
    #           :h1_title      - Concatenate all h1's on a page to form the
    #                            page title.
    #           :display_metadata - Whether or not to render a page's metadata on the page. Default: true
    #           :index_page    - The default page to retrieve or create if the
    #                            a directory is accessed.
    #           :bar_side      - Where the sidebar should be displayed, may be:
    #                             - :left
    #                             - :right
    #           :allow_uploads - Set to true to allow file uploads.
    #           :per_page_uploads - Whether uploads should be stored in a central
    #                            'uploads' directory, or in a directory named for
    #                            the page they were uploaded to.
    #           :filter_chain  - Override the default filter chain with your own.
    #
    # Returns a fresh Gollum::Repo.
    def initialize(path, options = {})
      options = self.class.default_options.merge(options)
      if path.is_a?(GitAccess)
        options[:access] = path
        path             = path.path
      end

      @path                 = path
      @repo_is_bare         = options.fetch :repo_is_bare, nil
      @page_file_dir        = options.fetch :page_file_dir, nil
      @page_file_dir        = Pathname.new("/#{@page_file_dir}").cleanpath.to_s[1..-1] if @page_file_dir
      @access               = options.fetch :access, GitAccess.new(path, @page_file_dir, @repo_is_bare)
      @base_path            = options.fetch :base_path, "/"
      @repo                 = @access.repo
      @ref                  = options.fetch :ref, self.class.default_ref
      @universal_toc        = options.fetch :universal_toc, false
      @mathjax              = options.fetch :mathjax, false
      @show_all             = options.fetch :show_all, false
      @link_compatibility   = options.fetch :link_compatibility, false
      @css                  = options.fetch :css, false
      @emoji                = options.fetch :emoji, false
      @critic_markup        = options.fetch :critic_markup, false
      @h1_title             = options.fetch :h1_title, false
      @display_metadata     = options.fetch :display_metadata, true
      @index_page           = options.fetch :index_page, 'Home'
      @bar_side             = options.fetch :sidebar, :right
      @user_icons           = ['gravatar', 'identicon'].include?(options[:user_icons]) ?
          options[:user_icons] : 'none'
      @allow_uploads        = options.fetch :allow_uploads, false
      @per_page_uploads     = options.fetch :per_page_uploads, false
      @metadata             = options.fetch :metadata, {}
      @filter_chain         = options.fetch :filter_chain,
                                            [:YAML, :BibTeX, :PlainText, :CriticMarkup, :TOC, :RemoteCode, :Code, :Macro, :Emoji, :Sanitize, :PlantUML, :Tags, :PandocBib, :Render]
      @filter_chain.delete(:Emoji) unless options.fetch :emoji, false
      @filter_chain.delete(:PandocBib) unless ::Gollum::MarkupRegisterUtils.using_pandoc?
      @filter_chain.delete(:CriticMarkup) unless options.fetch :critic_markup, false
    end

    # Public: check whether the wiki's git repo exists on the filesystem.
    #
    # Returns true if the repo exists, and false if it does not.
    def exist?
      @access.exist?
    end

    # Public: Get the formatted page for a given page name, version, and dir.
    #
    # path    - The String path to the the wiki page (may or may not include file extension).
    # version - The String version ID to find (default: @ref).
    #
    # Returns a Gollum::Page or nil if no matching page was found.
    def page(path, version = nil, global_match = false)
      ::Gollum::Page.find(self, path, version.nil? ? @ref : version, false, global_match)
    end

    # Public: Get the static file for a given name.
    #
    # name    - The full String pathname to the file.
    # version - The String version ID to find (default: @ref).
    # try_on_disk - If true, try to return just a reference to a file
    #               that exists on the disk.
    #
    # Returns a Gollum::File or nil if no matching file was found. Note
    # that if you specify try_on_disk=true, you may or may not get a file
    # for which on_disk? is actually true.
    def file(name, version = nil, try_on_disk = false)
      ::Gollum::File.find(self, name, version.nil? ? @ref : version, try_on_disk)
    end

    # Public: Create an in-memory Page with the given data and format. This
    # is useful for previewing what content will look like before committing
    # it to the repository.
    #
    # name   - The String name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    #
    # Returns the in-memory Gollum::Page.
    def preview_page(name, data, format)
      ::Gollum::PreviewPage.new(self, "#{name}.#{::Gollum::Page.format_to_ext(format.to_sym)}", data, @access.commit(@ref))
    end

    # Public: Write a new version of a page to the Gollum repo root.
    #
    # path   - The String path where the page will be written.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update.
    def write_page(path, format, data, commit = {})
     write(merge_path_elements(nil, path, format), data, commit)
    end

    # Public: Write a new version of a file to the Gollum repo.
    #
    # path   - The String path where the file will be written.
    # data   - The new String contents of the page.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update
    def write_file(name, data, commit = {})
      write(merge_path_elements(nil, name, nil), data, commit)
    end

    # Public: Write a file to the Gollum repo regardless of existing versions.
    #
    # path   - The String path where the file will be written.
    # data   - The new String contents of the page.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update
    def overwrite_file(name, data, commit = {})
      write(merge_path_elements(nil, name, nil), data, commit, force_overwrite = true)
    end

    # Public: Rename an existing page without altering content.
    #
    # page   - The Gollum::Page to update.
    # rename - The String extension-less full path of the page (leading '/' is ignored).
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update.
    # Returns false if the operation is a NOOP.
    def rename_page(page, rename, commit = {})
      return false if page.nil?
      return false if rename.nil? or rename.empty?

      (target_dir, target_name) = ::File.split(rename)
      (source_dir, source_name) = ::File.split(page.path)
      source_name               = page.filename_stripped

      # File.split gives us relative paths with ".", commiter.add_to_index doesn't like that.
      target_dir                = '' if target_dir == '.'
      source_dir                = '' if source_dir == '.'
      target_dir                = target_dir.gsub(/^\//, '')

      # if the rename is a NOOP, abort
      if source_dir == target_dir and source_name == target_name
        return false
      end

      multi_commit = !!commit[:committer]
      committer    = multi_commit ? commit[:committer] : Committer.new(self, commit)

      committer.delete(page.path)
      committer.add_to_index(merge_path_elements(target_dir, target_name, page.format), page.raw_data)

      committer.after_commit do |index, _sha|
        @access.refresh
        index.update_working_dir(merge_path_elements(source_dir, source_name, page.format))
        index.update_working_dir(merge_path_elements(target_dir, target_name, page.format))
      end

      multi_commit ? committer : committer.commit
    end

    # Public: Update an existing page with new content. The location of the
    # page inside the repository will not change. If the given format is
    # different than the current format of the page, the filename will be
    # changed to reflect the new format.
    #
    # page   - The Gollum::Page to update.
    # name   - The String extension-less name of the page.
    # format - The Symbol format of the page.
    # data   - The new String contents of the page.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update.
    def update_page(page, name, format, data, commit = {})
      name     ||= page.name
      format   ||= page.format
      dir      = ::File.dirname(page.path)
      dir      = nil if dir == '.'
      rename   = (page.name != name || page.format != format)
      new_path = ::File.join([dir, self.page_file_name(name, format)].compact) if rename

      multi_commit = !!commit[:committer]
      committer    = multi_commit ? commit[:committer] : Committer.new(self, commit)

      if !rename
        committer.add(page.path, normalize(data))
      else
        committer.delete(page.path)
        committer.add_to_index(new_path, data)
      end

      committer.after_commit do |index, _sha|
        @access.refresh
        index.update_working_dir(page.path)
        index.update_working_dir(new_path) if rename
      end

      multi_commit ? committer : committer.commit
    end

    # Public: Delete a page.
    #
    # page   - The Gollum::Page to delete.
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update.
    def delete_page(page, commit)
      delete_file(page.url_path, commit)
    end

    # Public: Delete a file.
    #
    # path   - The path to the file to delete
    # commit - The commit Hash details:
    #          :message   - The String commit message.
    #          :name      - The String author full name.
    #          :email     - The String email address.
    #          :parent    - Optional Gollum::Git::Commit parent to this update.
    #          :tree      - Optional String SHA of the tree to create the
    #                       index from.
    #          :committer - Optional Gollum::Committer instance.  If provided,
    #                       assume that this operation is part of batch of
    #                       updates and the commit happens later.
    #
    # Returns the String SHA1 of the newly written version, or the
    # Gollum::Committer instance if this is part of a batch update.
    def delete_file(path, commit)
      fullpath     = ::File.join([page_file_dir, path].compact)
      multi_commit = !!commit[:committer]
      committer    = multi_commit ? commit[:committer] : Committer.new(self, commit)

      committer.delete(fullpath)

      committer.after_commit do |index, _sha|
        dir = '' if dir == '.'
        @access.refresh
        index.update_working_dir(fullpath)
      end

      multi_commit ? committer : committer.commit
    end

    # Public: Applies a reverse diff for a given page.  If only 1 SHA is given,
    # the reverse diff will be taken from its parent (^SHA...SHA).  If two SHAs
    # are given, the reverse diff is taken from SHA1...SHA2.
    #
    # page   - The Gollum::Page to delete.
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    # commit - The commit Hash details:
    #          :message - The String commit message.
    #          :name    - The String author full name.
    #          :email   - The String email address.
    #          :parent  - Optional Gollum::Git::Commit parent to this update.
    # Returns a String SHA1 of the new commit, or nil if the reverse diff does
    # not apply.
    def revert_page(page, sha1, sha2 = nil, commit = {})
      return false unless page
      left, right, options = parse_revert_options(sha1, sha2, commit)
      commit_and_update_paths(@repo.git.revert_path(page.path, left, right), [page.path], options)
    end

    # Public: Applies a reverse diff to the repo.  If only 1 SHA is given,
    # the reverse diff will be taken from its parent (^SHA...SHA).  If two SHAs
    # are given, the reverse diff is taken from SHA1...SHA2.
    #
    # sha1   - String SHA1 of the earlier parent if two SHAs are given,
    #          or the child.
    # sha2   - Optional String SHA1 of the child.
    # commit - The commit Hash details:
    #          :message - The String commit message.
    #          :name    - The String author full name.
    #          :email   - The String email address.
    #
    # Returns a String SHA1 of the new commit, or nil if the reverse diff does
    # not apply.
    def revert_commit(sha1, sha2 = nil, commit = {})
      left, right, options = parse_revert_options(sha1, sha2, commit)
      tree, files = repo.git.revert_commit(left, right)
      commit_and_update_paths(tree, files, options)
    end

    # Public: Lists all pages for this wiki.
    #
    # treeish - The String commit ID or ref to find  (default:  @ref)
    #
    # Returns an Array of Gollum::Page instances.
    def pages(treeish = nil)
      tree_list(treeish || @ref, true, false)
    end

    # Public: Lists all non-page files for this wiki.
    #
    # treeish - The String commit ID or ref to find  (default:  @ref)
    #
    # Returns an Array of Gollum::File instances.
    def files(treeish = nil)
      tree_list(treeish || @ref, false, true)
    end

    # Public: Returns the number of pages accessible from a commit
    #
    # ref - A String ref that is either a commit SHA or references one.
    #
    # Returns a Fixnum
    def size(ref = nil)
      tree_map_for(ref || @ref).inject(0) do |num, entry|
        num + (::Gollum::Page.valid_page_name?(entry.name) ? 1 : 0)
      end
    rescue Gollum::Git::NoSuchShaFound
      0
    end

    # Public: Search all pages for this wiki.
    #
    # query - The string to search for
    #
    # Returns an Array with Objects of page name and count of matches
    def search(query)
      options = {:path => page_file_dir, :ref => ref}
      search_terms = query.scan(/"([^"]+)"|(\S+)/).flatten.compact.map {|term| Regexp.escape(term)}
      search_terms_regex = search_terms.join('|')
      query = /^(.*(?:#{search_terms_regex}).*)$/i
      results = @repo.git.grep(search_terms, options) do |name, data|
        result = {:count => 0}
        result[:name] = extract_page_file_dir(name)
        result[:filename_count] = result[:name].scan(/#{search_terms_regex}/i).size
        result[:context] = []
        if data
          data.scan(query) do |match|
            result[:context] << match.first
            result[:count] += match.first.scan(/#{search_terms_regex}/i).size
          end
        end
        ((result[:count] + result[:filename_count]) == 0) ? nil : result
      end
      [results, search_terms]
    end

    # Public: All of the versions that have touched the Page.
    #
    # options - The options Hash:
    #           :page_num  - The Integer page number (default: 1).
    #           :per_page  - The Integer max count of items to return.
    #
    # Returns an Array of Gollum::Git::Commit.
    def log(options = {})
      @repo.log(@ref, nil, log_pagination_options(options))
    end

    # Returns the latest changes in the wiki (globally)
    #
    # options - The options Hash:
    #           :max_count  - The Integer number of items to return.
    #
    # Returns an Array of Gollum::Git::Commit.
    def latest_changes(options={})
      options[:max_count] = 10 unless options[:max_count]
      @repo.log(@ref, page_file_dir, options)
    end

    # Public: Refreshes just the cached Git reference data.  This should
    # be called after every Gollum update.
    #
    # Returns nothing.
    def clear_cache
      @access.refresh
    end

    def redirects
      if @redirects.nil? || @redirects.stale?
        @redirects = {}.extend(::Gollum::Redirects)
        @redirects.init(self)
        @redirects.load
      end
      @redirects
    end

    def add_redirect(old_path, new_path)
      redirects[old_path] = new_path
      redirects.dump
    end

    def remove_redirect(path)
      redirects.tap{|k| k.delete(path)}
      redirects.dump
    end

    #########################################################################
    #
    # Internal Methods
    #
    #########################################################################

    # The Gollum::Git::Repo associated with the wiki.
    #
    # Returns the Gollum::Git::Repo.
    attr_reader :repo

    # The String path to the Git repository that holds the Gollum site.
    #
    # Returns the String path.
    attr_reader :path

    # Toggles display of universal table of contents
    attr_reader :universal_toc

    # Toggles mathjax.
    attr_reader :mathjax

    # Toggles user icons. Default: 'none'
    attr_reader :user_icons

    # Toggles showing all files in files view. Default is false.
    # When false, only valid pages in the git repo are displayed.
    attr_reader :show_all

    # Enable 4.x compatibility behavior for links
    attr_reader :link_compatibility

    # Toggles file upload functionality.
    attr_reader :allow_uploads

    # Toggles whether uploaded files go into 'uploads', or a directory
    # named after the page they were uploaded to.
    attr_reader :per_page_uploads

    # Normalize the data.
    #
    # data - The String data to be normalized.
    #
    # Returns the normalized data String.
    def normalize(data)
      data.gsub(/\r/, '')
    end

    # Assemble a Page's filename from its name and format.
    #
    # name   - The String name of the page (should be pre-canonicalized).
    # format - The Symbol format of the page.
    #
    # Returns the String filename.
    def page_file_name(name, format)
      format.nil? ? name : "#{name}.#{::Gollum::Page.format_to_ext(format)}"
    end

    # Fill an array with a list of pages and files in the wiki.
    #
    # ref - A String ref that is either a commit SHA or references one.
    #
    # Returns a flat Array of Gollum::Page and Gollum::File instances.
    def tree_list(ref = @ref, pages=true, files=true)
      if (sha = @access.ref_to_sha(ref))
        commit = @access.commit(sha)
        tree_map_for(sha).inject([]) do |list, entry|
          if ::Gollum::Page.valid_page_name?(entry.name)
            list << entry.page(self, commit) if pages
          elsif files && !entry.name.start_with?('_') && !::Gollum::Page.protected_files.include?(entry.name)
            list << entry.file(self, commit)
          end
          list
        end
      else
        []
      end
    end

    # Gets the default name for commits.
    #
    # Returns the String name.
    def default_committer_name
      @default_committer_name ||= \
        @repo.config['user.name'] || self.class.default_committer_name
    end

    # Gets the default email for commits.
    #
    # Returns the String email address.
    def default_committer_email
      email = @repo.config['user.email']
      email = email.delete('<>') if email
      @default_committer_email ||= email || self.class.default_committer_email
    end

    # Gets the commit object for the given ref or sha.
    #
    # ref - A string ref or SHA pointing to a valid commit.
    #
    # Returns a Gollum::Git::Commit instance.
    def commit_for(ref)
      @access.commit(ref)
    rescue Gollum::Git::NoSuchShaFound
    end

    # Finds a full listing of files and their blob SHA for a given ref.  Each
    # listing is cached based on its actual commit SHA.
    #
    # ref - A String ref that is either a commit SHA or references one.
    # ignore_page_file_dir - Boolean, if true, searches all files within the git repo, regardless of dir/subdir
    #
    # Returns an Array of BlobEntry instances.
    def tree_map_for(ref, ignore_page_file_dir = false)
      if ignore_page_file_dir && !@page_file_dir.nil?
        @root_access ||= GitAccess.new(path, nil, @repo_is_bare)
        @root_access.tree(ref)
      else
        @access.tree(ref)
      end
    rescue Gollum::Git::NoSuchShaFound
      []
    end

    def inspect
      %(#<#{self.class.name}:#{object_id} #{@repo.path}>)
    end

    # Public: Creates a Sanitize instance
    #
    # Returns a Sanitize instance.
    def sanitizer
      @sanitizer ||= Gollum::Sanitization.new(Gollum::Markup.to_xml_opts)
    end

    private

    def parse_revert_options(sha1, sha2, commit = {})
      if sha2.is_a?(Hash)
        return "#{sha1}^", sha1, sha2
      elsif sha2.nil?
        return "#{sha1}^", sha1, commit
      else
        return sha1, sha2, commit
      end
    end

    def commit_and_update_paths(tree, paths, options)
      return false unless tree
      committer = Committer.new(self, options)
      parent    = committer.parents[0]

      committer.options[:tree] = tree

      committer.after_commit do |index, _sha|
        @access.refresh

        paths.each do |path|
          index.update_working_dir(path)
        end
      end

      committer.commit
    end

    # Conjoins elements of a page or file path and prefixes the page_file_dir.
    # Throws Gollum::IllegalDirectoryPath if page_file_dir is set, and the resulting
    # path is not below it (e.g. if the dir or name contained '../')
    #
    # dir    - The String directory path
    # name   - The String name of the Page or File
    # format - The Symbol format of the page. Should be nil for Files.
    #
    # Returns a String path.  .
    def merge_path_elements(dir, name, format)
      result = ::File.join([@page_file_dir, dir, self.page_file_name(name, format)].compact)
      result = Pathname.new(result).cleanpath.to_s
      if @page_file_dir
        raise Gollum::IllegalDirectoryPath unless result.start_with?("#{@page_file_dir}/")
        result
      else
        result[0] == '/' ? result[1..-1] : result
      end
    end

    def extract_page_file_dir(path)
      @page_file_dir ? path[@page_file_dir.length+1..-1] : path
    end

    def write(path, data, commit = {}, force_overwrite = false)
      multi_commit = !!commit[:committer]
      committer    = multi_commit ? commit[:committer] : Committer.new(self, commit)
      committer.add_to_index(path, data, commit, force_overwrite)

      committer.after_commit do |index, _sha|
        @access.refresh
        index.update_working_dir(path)
      end

      multi_commit ? committer : committer.commit
    end

  end
end
