module Gollum
  class Icon
    # See if octicons gem is available
    @@octicons = false
    begin
      require 'octicons'
      @@octicons = true
    rescue LoadError; end
    
    def self.get_icon(name, options={}, for_css=false)
      defaults = {height: 16, width: 16, class: ''}
      options = defaults.merge(options)
      if for_css
        options.delete(:height)
        options.delete(:width)
      end
      if @@octicons && octicon = ::Octicons::Octicon.new(name, options)
        octicon.to_svg
      else
        height = %Q(height="#{options[:height]}") if options[:height]
        width = %Q(width="#{options[:width]}") if options[:width]
        cls = %Q(class="octicon octicon-alert #{options[:class]}")
        xmlns = %Q(xmlns="http://www.w3.org/2000/svg") if for_css
        title = %Q(<title>Octicons are at present not available</title>)
        viewbox = %Q(viewBox="0 0 24 24") if options[:width]
        %Q(<svg #{height} #{width} #{cls} #{viewbox} #{xmlns} version="1.1" aria-hidden="true">#{title}<path d="M13 17.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0Zm-.25-8.25a.75.75 0 0 0-1.5 0v4.5a.75.75 0 0 0 1.5 0v-4.5Z"></path><path d="M9.836 3.244c.963-1.665 3.365-1.665 4.328 0l8.967 15.504c.963 1.667-.24 3.752-2.165 3.752H3.034c-1.926 0-3.128-2.085-2.165-3.752Zm3.03.751a1.002 1.002 0 0 0-1.732 0L2.168 19.499A1.002 1.002 0 0 0 3.034 21h17.932a1.002 1.002 0 0 0 .866-1.5L12.866 3.994Z"></path></svg>)
      end
    end
    
  end # class
end # module


