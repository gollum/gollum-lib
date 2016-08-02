# ~*~ encoding: utf-8 ~*~
require 'digest/sha1'
require 'cgi'
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

    class << self

      # Only use the formats that are specified in config.rb
      def formats
        if defined? Gollum::Page::FORMAT_NAMES
          @formats.select { |_, value| Gollum::Page::FORMAT_NAMES.values.include? value[:name] }
        else
          @formats
        end
      end

      # Register a file extension and associated markup type
      #
      # ext     - The file extension
      # name    - The name of the markup type
      # options - Hash of options:
      #           regexp - Regexp to match against.
      #                    Defaults to exact match of ext.
      #
      # If given a block, that block will be registered with GitHub::Markup to
      # render any matching pages
      def register(ext, name, options = {}, &block)
        @formats[ext] = { :name => name,
          :regexp => options.fetch(:regexp, Regexp.new(ext.to_s)),
          :reverse_links => options.fetch(:reverse_links, false) }
      end
    end

    attr_accessor :toc
    attr_accessor :metadata
    attr_reader :encoding
    attr_reader :sanitize
    attr_reader :format
    attr_reader :wiki
    attr_reader :page
    attr_reader :parent_page
    attr_reader :sub_page
    attr_reader :name
    attr_reader :include_levels
    attr_reader :to_xml_opts
    attr_reader :dir

    # Initialize a new Markup object.
    #
    # page - The Gollum::Page.
    #
    # Returns a new Gollum::Markup object, ready for rendering.
    def initialize(page)
      if page
        @wiki        = page.wiki
        @name        = page.filename
        @data        = page.text_data
        @version     = page.version.id if page.version
        @format      = page.format
        @sub_page    = page.sub_page
        @parent_page = page.parent_page
        @page        = page
        @dir         = ::File.dirname(page.path)
      end
      @metadata    = nil
      @to_xml_opts = { :save_with => Nokogiri::XML::Node::SaveOptions::DEFAULT_XHTML ^ 1, :indent => 0, :encoding => 'UTF-8' }
    end

    def reverse_links?
      self.class.formats[@format][:reverse_links]
    end

    # Render data using default chain in the target format.
    #
    # data - the data to render
    # format - format to use as a symbol
    # name - name using the extension of the format
    #
    # Returns the processed data
    def render_default(data, format=:markdown, name='render_default.md')
      # set instance vars so we're able to render data without a wiki or page.
      @format = format
      @name   = name

      chain = [:Metadata, :PlainText, :Emoji, :TOC, :RemoteCode, :Code, :Sanitize, :WSD, :Tags, :Render]

      filter_chain = chain.map do |r|
        Gollum::Filter.const_get(r).new(self)
      end

      process_chain data, filter_chain
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

      # Then we process the data through the chain *backwards*
      filter_chain.reverse.each do |filter|
        data = filter.process(data)
      end

      # Finally, a little bit of cleanup, just because
      data.gsub!(/<p><\/p>/) do
        ''
      end

      data
    end

    # Render the content with Gollum wiki syntax on top of the file's own
    # markup language.
    #
    # no_follow - Boolean that determines if rel="nofollow" is added to all
    #             <a> tags.
    # encoding  - Encoding Constant or String.
    #
    # Returns the formatted String content.
    def render(no_follow = false, encoding = nil, include_levels = 10)
      @sanitize = no_follow ?
          @wiki.history_sanitizer :
          @wiki.sanitizer

      @encoding       = encoding
      @include_levels = include_levels

      data         = @data.dup
      filter_chain = @wiki.filter_chain.map do |r|
        Gollum::Filter.const_get(r).new(self)
      end

      # Since the last 'extract' action in our chain *should* be the markup
      # to HTML converter, we now have HTML which we can parse and yield, for
      # anyone who wants it
      if block_given?
        yield Nokogiri::HTML::DocumentFragment.parse(data)
      end

      process_chain data, filter_chain
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

  MarkupGFM = Markup
end
