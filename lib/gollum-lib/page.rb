# ~*~ encoding: utf-8 ~*~
module Gollum
  class Page < Gollum::File
    include Pagination
    
    SUBPAGENAMES = [:header, :footer, :sidebar]

    class << self
      # For use with self.find: returns true if the given query corresponds to the in-repo path of the BlobEntry. 
      #
      # query     - The String path to match.
      # entry     - The BlobEntry to check against.
      def path_match(query, entry)
        return false if "#{entry.name}".empty?
        return false unless valid_extension?(entry.name)
        entry_name = valid_extension?(query) ? entry.name : strip_filename(entry.name)
        query == ::File.join('/', entry.dir, entry_name)
      end
    end

    # Checks if a filename has a valid, registered extension
    #
    # filename - String filename, like "Home.md".
    #
    # Returns true or false.
    def self.valid_extension?(filename)
      Gollum::Markup.extensions.include?(::File.extname(filename.to_s).sub(/^\./,''))
    end

    # Checks if a filename has a valid extension understood by GitHub::Markup.
    # Also, checks if the filename is subpages (such as _Footer.md).
    #
    # filename - String filename, like "Home.md".
    #
    # Returns true or false.
    def self.valid_page_name?(filename)
      subpage_names = SUBPAGENAMES.map(&:capitalize).join("|")
      filename =~ /^_(#{subpage_names})/ ? false : self.valid_extension?(filename)
    end

    # Public: The format of a given filename.
    #
    # filename - The String filename.
    #
    # Returns the Symbol format of the page; one of the registered format types
    def self.format_for(filename)
      ext = ::File.extname(filename.to_s).sub(/^\./,'')
      Gollum::Markup.formats.each_pair do |name, format|
        return name if format[:extensions].include?(ext)
      end
      nil
    end

    # Reusable filter to strip extension and path from filename
    #
    # filename - The string path or filename to strip
    #
    # Returns the stripped String.
    def self.strip_filename(filename)
      ::File.basename(filename.to_s, ::File.extname(filename.to_s))
    end

    # Public: Initialize a Page.
    #
    # wiki - The Gollum::Wiki
    # blob - The Gollum::Git::Blob
    # path - The String path
    # version - The String SHA or Gollum::Git::Commit version
    # try_on_disk - If true, try to get an on disk reference for this page.
    #
    # Returns a newly initialized Gollum::Page.
    def initialize(wiki, blob, path, version, try_on_disk = false)
      super
      @formatted_data = nil
      @doc            = nil
      @parent_page    = nil
      @historical     = @version.to_s == version.to_s
    end

    # Parent page if this is a sub page
    #
    # Returns a Page
    attr_accessor :parent_page

    # Public: The on-disk filename of the page with extension stripped.
    #
    # Returns the String name.
    def filename_stripped
      self.class.strip_filename(filename)
    end

    # Public: The canonical page name without extension.
    #
    # Returns the String name.
    def name
      self.class.strip_filename(filename)
    end

    # Public: The title will be constructed from the
    # filename by stripping the extension.
    #
    # Returns the fully sanitized String title.
    def title
      Sanitize.clean(name).strip
    end

    # Public: Determines if this is a sub-page
    # Sub-pages have filenames beginning with an underscore
    #
    # Returns true or false.
    def sub_page
      filename =~ /^_/
    end

    # Public: Defines title for page.rb
    #
    # Returns the String title
    def url_path_title
      metadata_title || name
    end

    # Public: Metadata title
    #
    # Set with <!-- --- title: New Title --> in page content
    #
    # Returns the String title or nil if not defined
    def metadata_title
      metadata ? metadata['title'] : nil
    end

    # Public: Whether or not to display the metadata
    def display_metadata?
      return false if (metadata.keys - ['title', 'header_enum']).empty?
      return false if metadata['display_metadata'] == false
      @wiki.display_metadata
    end

    # Public: A text data encoded in specified encoding.
    #
    # encoding - An Encoding or nil
    #
    # Returns a character encoding aware String.
    def text_data(encoding=nil)
      if raw_data.respond_to?(:encoding)
        raw_data.force_encoding(encoding || Encoding::UTF_8)
      else
        raw_data
      end
    end

    # Public: The formatted contents of the page.
    #
    # encoding - Encoding Constant or String.
    #
    # Returns the String data.
    def formatted_data(encoding = nil, include_levels = 10, &block)
      return nil unless @blob

      if @formatted_data && @doc then
        yield @doc if block_given?
      else
        @formatted_data = markup.render(historical?, encoding, include_levels) do |doc|
          @doc = doc
          yield doc if block_given?
        end
      end

      @formatted_data
    end

    # Public: The table of contents of the page.
    #
    # formatted_data - page already marked up in html.
    #
    # Returns the String data.
    def toc_data
      return @parent_page.toc_data if @parent_page and @sub_page
      formatted_data if markup.toc == nil
      markup.toc
    end

    # Public: Embedded metadata.
    #
    # Returns Hash of metadata.
    def metadata
      unless @metadata
        formatted_data if markup.metadata == nil
        @metadata = @wiki.metadata.merge(markup.metadata || {})
      else
        @metadata
      end
    end

    # Public: The format of the page.
    #
    # Returns the Symbol format of the page; one of the registered format types
    def format
      self.class.format_for(@blob.name)
    end

    # Gets the Gollum::Markup instance that will render this page's content.
    #
    # Returns a Gollum::Markup instance.
    def markup
      @markup ||= ::Gollum::Markup.new(self)
    end

    # Public: All of the versions that have touched the Page.
    #
    # options - The options Hash:
    #           :page_num  - The Integer page number (default: 1).
    #           :per_page  - The Integer max count of items to return.
    #           :follow    - Follow's a file across renames, slower.  (default: false)
    #
    # Returns an Array of Gollum::Git::Commit.
    def versions(options = {})
      @wiki.repo.git.versions_for_path(@path, @wiki.ref, log_pagination_options(options))
    end

    # Public: The last version that has touched the Page. Can be nil.
    #
    # Returns Gollum::Git::Commit, or nil.
    def last_version
      return @last_version if defined? @last_version
      @last_version = @wiki.repo.git.versions_for_path(@path, @wiki.ref, {:max_count => 1}).first
    end

    # Public: The first 7 characters of the current version.
    #
    # Returns the first 7 characters of the current version.
    def version_short
      version.to_s[0, 7]
    end

    # Public: The header Page.
    #
    # Returns the header Page or nil if none exists.
    def header
      find_sub_pages unless defined?(@header)
      @header
    end

    # Public: The footer Page.
    #
    # Returns the footer Page or nil if none exists.
    def footer
      find_sub_pages unless defined?(@footer)
      @footer
    end

    # Public: The sidebar Page.
    #
    # Returns the sidebar Page or nil if none exists.
    def sidebar
      find_sub_pages unless defined?(@sidebar)
      @sidebar
    end

    # Gets a Boolean determining whether this page is a historical version.
    # Historical pages are pulled using exact SHA hashes and format all links
    # with rel="nofollow"
    #
    # Returns true if the page is pulled from a named branch or tag, or false.
    def historical?
      !!@historical
    end

    # Convert a format Symbol into an extension String.
    #
    # format - The format Symbol.
    #
    # Returns the String extension (no leading period).
    def self.format_to_ext(format)
      format == :markdown ? "md" : format.to_s
    end

    # The underlying wiki repo.
    #
    # Returns the Gollum::Wiki containing the page.
    attr_reader :wiki

    # The full directory path for the given tree.
    #
    # treemap - The Hash treemap containing parentage information.
    # tree    - The Gollum::Git::Tree for which to compute the path.
    #
    # Returns the String path.
    def tree_path(treemap, tree)
      if (ptree = treemap[tree])
        "#{tree_path(treemap, ptree)}#{::File::SEPARATOR}#{tree.name}"
      else
        ''
      end
    end

    # Loads sub pages. Sub page names (footers, headers, sidebars) are prefixed with
    # an underscore to distinguish them from other Pages. If there is not one within
    # the current directory, starts walking up the directory tree to try and find one
    # within parent directories.
    def find_sub_pages(subpagenames = SUBPAGENAMES, map = nil)
      subpagenames.each{|subpagename| instance_variable_set("@#{subpagename}", nil)}
      return nil if self.filename =~ /^_/ || ! self.version

      map ||= @wiki.tree_map_for(@wiki.ref, true)
      valid_names = subpagenames.map(&:capitalize).join("|")
      # From Ruby 2.2 onwards map.select! could be used
      map = map.select{|entry| entry.name =~ /^_(#{valid_names})/ }
      return if map.empty?

      subpagenames.each do |subpagename|
        dir = ::Pathname.new(self.path)
        while dir = dir.parent do
          subpageblob = map.find do |blob_entry|

            filename = "_#{subpagename.to_s.capitalize}"
            searchpath = dir == Pathname.new('.') ? Pathname.new(filename) : dir + filename
            entrypath = ::Pathname.new(blob_entry.path)
            # Ignore extentions
            entrypath = entrypath.dirname + entrypath.basename(entrypath.extname)
            entrypath == searchpath
          end

          if subpageblob
            instance_variable_set("@#{subpagename}", subpageblob.page(@wiki, @version) )
            instance_variable_get("@#{subpagename}").parent_page = self
            break
          end

          break if dir == Pathname.new('.')
        end
      end
    end

    def inspect
      %(#<#{self.class.name}:#{object_id} #{name} (#{format}) @wiki=#{@wiki.repo.path.inspect}>)
    end

  end

  class PreviewPage < Gollum::Page
    include Pagination

    SUBPAGENAMES.each do |subpage|
      define_method(subpage) do
        instance_variable_get("@#{subpage}")
      end
      define_method("set_#{subpage}") do |val|
        instance_variable_set("@#{subpage}", PreviewPage.new(@wiki, "_#{subpage.to_s.capitalize}.md", val, @version, self))
      end
    end

    attr_accessor :path

    def initialize(wiki, name, data, version, parent_page = nil)
      @wiki           = wiki 
      @path           = name
      @blob           = OpenStruct.new(:name => name, :data => data, :is_symlink => false)
      @version        = version
      @formatted_data = nil
      @doc            = nil
      @parent_page    = parent_page
      @historical     = false
    end
  end

end
