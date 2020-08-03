module Gollum
  class Macro
    # Find the macro named, create an instance of that, and return it
    def self.instance(macro_name, wiki, page)
      begin
        self.const_get(macro_name).new(wiki, page)
      rescue NameError
        Unknown_Macro.new(macro_name)
      end
    end

    def initialize(wiki, page)
      @wiki = wiki
      @page = page
    end

    def render(*_args)
      raise ArgumentError,
            "#{self.class} does not implement #render.  "+
            "This is a bug in #{self.class}."
    end
    
    protected
    def html_error(s)
      "<p class=\"gollum-error\">#{s}</p>"
    end

    def active_page
      return @page.parent_page || @page
    end

    # The special class we reserve for only the finest of screwups.  The
    # underscore is to make sure nobody can define a real, callable macro
    # with the same name, because that would be... exciting.
    class Unknown_Macro < Macro
      def initialize(macro_name)
        @macro_name = macro_name
      end

      def render(*_args)
        "!!!Unknown macro: #{@macro_name}!!!"
      end
    end
  end
end

Dir[File.expand_path('../macro/*.rb', __FILE__)].each { |f| require f }
