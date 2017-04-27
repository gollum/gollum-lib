# A "filter", in Gollum-speak, is an object which extracts tokens from an
# input stream of an arbitrary markup language, then replaces them with a
# final form in a rendered form of the same document.  Filters are composed
# into a "filter chain", which forms the order in which filters are applied
# in both the extraction and processing phases (processing happens in the
# reverse order to extraction).  A single instance of a filter class is used
# for both the extraction and processing, so you can store internal state
# from the extraction phase for use in the processing phase.
#
# Any class which is to be used as a filter must have an `initialize` method
# which takes a single mandatory argument (the instance of the `Markup`
# class we're being called from), and must implement two methods: `extract`
# and `process`, both of which must take a string as input and return a
# (possibly modified) form of that string as output.
#
# An example rendering session: consider a filter chain with three filters
# in it, :A, :B, and :C (filter chains are specified as symbols, which are
# taken to be class names within the Gollum::Filter namespace).  An
# equivalent of the following will take place:
#
#     a = Gollum::Filter.const_get(:A).new
#     b = Gollum::Filter.const_get(:B).new
#     c = Gollum::Filter.const_get(:C).new
#
#     data = "<some markup>"
#
#     data = a.extract(data)
#     data = b.extract(data)
#     data = c.extract(data)
#
#     data = c.process(data)
#     data = b.process(data)
#     data = a.process(data)
#
#     # `data` now contains the rendered document, ready for processing
#
# Note how the extraction steps go in the order of the filter chain, while
# the processing steps go in the reverse order.  There hasn't (yet) been a
# case where that is a huge problem.
#
# If your particular filter doesn't need to do something with either the
# original markup or rendered forms, you can simply define the relevant
# method to be a pass-through (`def extract(d) d; end`), but you *must*
# define both methods yourself.
#     
module Gollum
  class Filter
    include Gollum::Helpers

    def self.to_sym
      name.split('::').last.to_sym
    end

    # Setup the object.  Sets `@markup` to be the instance of Gollum::Markup that
    # is running this filter chain, and sets `@map` to be an empty hash (for use
    # in your extract/process operations).
    def initialize(markup)
      @markup = markup
      @map    = {}
    end

    def do_process(_d)
      skip? ? _d : process(_d)
    end

    def do_extract(_d)
      skip? ? _d : extract(_d)
    end

    def extract(_d)
      raise RuntimeError,
            "#{self.class} has not implemented ##extract!"
    end

    def process(_d)
      raise RuntimeError,
            "#{self.class} has not implemented ##process!"
    end

    private
    
    def skip?
      @markup.skip_filter?(self.class.to_sym)
    end

    protected
    # Render a (presumably) non-fatal error as HTML
    #
    def html_error(message)
      "<p class=\"gollum-error\">#{message}</p>"
    end
  end
end

# Load all standard filters
Dir[File.expand_path('../filter/*.rb', __FILE__)].each { |f| require f }
