# ~*~ encoding: utf-8 ~*~
require 'digest/sha1'
require 'rouge'
require 'base64'

require File.expand_path '../helpers', __FILE__

# Use pygments if it's installed
begin
  require 'pygments'
  Pygments.start
rescue Exception
end

module Gollum

  class Markup
    include Helpers

    @formats = {}
    @extensions = []

    class << self

      def to_xml_opts
        { :save_with => Nokogiri::XML::Node::SaveOptions::DEFAULT_XHTML ^ 1, :indent => 0, :encoding => 'UTF-8' }
      end

      # Only use the formats that are specified in config.rb
      def formats
        if defined? Gollum::Page::FORMAT_NAMES
          @formats.select { |_, value| Gollum::Page::FORMAT_NAMES.values.include? value[:name] }
        else
          @formats
        end
      end

      def extensions
        @extensions
      end

      # Register a file format
      #
      # ext     - The file extension
      # name    - The name of the markup type
      # options - Hash of options:
      #           extensions - Array of valid file extensions, for instance ['md']
      #           enabled - Whether the markup is enabled
      #
      # If given a block, that block will be registered with GitHub::Markup to
      # render any matching pages
      def register(ext, name, options = {}, &block)
        if options[:regexp] then
          STDERR.puts <<-EOS
          Warning: attempted to register a markup (name: #{name.to_s}) by passing the deprecated :regexp option.
          Please pass an Array of valid file extensions (:extensions => ['ext1', 'ext2']) instead.
          EOS
        end
        new_extension = options.fetch(:extensions, [ext.to_s])
        @formats[ext] = { :name => name,
          :extensions => new_extension,
          :reverse_links => options.fetch(:reverse_links, false),
          :skip_filters => options.fetch(:skip_filters, nil),
          :enabled => options.fetch(:enabled, true) }
        @extensions.concat(new_extension)
      end
    end

    attr_accessor :toc
    attr_accessor :metadata
    attr_reader :encoding
    attr_reader :format
    attr_reader :wiki
    attr_reader :page
    attr_reader :parent_page
    attr_reader :sub_page
    attr_reader :name
    attr_reader :include_levels
    attr_reader :dir
    attr_reader :historical

    # Initialize a new Markup object.
    #
    # page - The Gollum::Page.
    #
    # Returns a new Gollum::Markup object, ready for rendering.
    def initialize(page)
      @wiki        = page.wiki
      @name        = page.filename
      @data        = page.text_data
      @version     = page.version.id if page.version
      @format      = page.format
      @sub_page    = page.sub_page
      @parent_page = page.parent_page
      @page        = page
      @dir         = ::File.dirname(page.path)
      @metadata    = nil
    end

    # Whether or not this markup's format uses reversed-order links ([description | url] rather than [url | description]). Defaults to false.
    def reverse_links?
      self.class.formats[@format][:reverse_links]
    end

    # Whether or not a particular filter should be skipped for this format.
    def skip_filter?(filter)
      if self.class.formats[@format][:skip_filters].respond_to?(:include?)
        self.class.formats[@format][:skip_filters].include?(filter)
      elsif self.class.formats[@format][:skip_filters].respond_to?(:call)
        self.class.formats[@format][:skip_filters].call(filter)
      else
        false
      end
    end

    # Process the filter chain
    #
    # data - the data to send through the chain
    # filter_chain - the chain to process
    #
    # Returns the formatted data
    def process_chain(data, filter_chain)
      # First we extract the data through the chain...
      filter_chain.each do |filter|
        data = filter.extract(data)
      end

      # Since the last 'extract' action in our chain *should* be the markup
      # to HTML converter, we now have HTML which we can parse and yield, for
      # anyone who wants it
      yield Nokogiri::HTML::DocumentFragment.parse(data) if block_given?

      # Then we process the data through the chain *backwards*
      filter_chain.reverse.each do |filter|
        data = filter.process(data)
      end

      data
    end

    # Render the content with Gollum wiki syntax on top of the file's own
    # markup language. Takes an optional block that will be executed after
    # the markup rendering step in the filter chain.
    #
    # no_follow - Boolean that determines if rel="nofollow" is added to all
    #             <a> tags.
    # encoding  - Encoding Constant or String.
    #
    # Returns the formatted String content.
    def render(no_follow = false, encoding = nil, include_levels = 10, &block)
      @historical     = no_follow
      @encoding       = encoding
      @include_levels = include_levels

      data = @data.dup

      filter_chain = @wiki.filter_chain.reject {|filter| skip_filter?(filter)}
      filter_chain.map! do |filter_sym|
        Gollum::Filter.const_get(filter_sym).new(self)
      end

      process_chain(data, filter_chain, &block)
    end

    # Find the given file in the repo.
    #
    # name - The String absolute or relative path of the file.
    #
    # Returns the Gollum::File or nil if none was found.
    def find_file(name, version=@version)
      if name =~ /^\//
        @wiki.file(name[1..-1], version)
      else
        path = @dir == '.' ? name : ::File.join(@dir, name)
        @wiki.file(path, version)
      end
    end

    # Hook for getting the formatted value of extracted tag data.
    #
    # type - Symbol value identifying what type of data is being extracted.
    # id   - String SHA1 hash of original extracted tag data.
    #
    # Returns the String cached formatted data, or nil.
    def check_cache(type, id)
    end

    # Hook for caching the formatted value of extracted tag data.
    #
    # type - Symbol value identifying what type of data is being extracted.
    # id   - String SHA1 hash of original extracted tag data.
    # data - The String formatted value to be cached.
    #
    # Returns nothing.
    def update_cache(type, id, data)
    end
  end

end
