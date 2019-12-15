# ~*~ encoding: utf-8 ~*~
require 'octicons'

# Replace specified tokens with dynamically generated content.
class Gollum::Filter::Macro < Gollum::Filter
  def extract(data)
    quoted_arg   = %r{".*?"}
    unquoted_arg = %r{[^,)]+}
    named_arg    = %r{[a-z0-9_]+=".*?"}
    
    arg = %r{(?:#{quoted_arg}|#{unquoted_arg}|#{named_arg})}
    arg_list = %r{(\s*|#{arg}(?:\s*,\s*#{arg})*)}

    data.gsub(/('?)\<\<\s*([A-Z][A-Za-z0-9]*)\s*\(#{arg_list}\)\s*\>\>/) do
      next CGI.escape_html($&[1..-1]) unless Regexp.last_match[1].empty?
      id = "#{open_pattern}#{Digest::SHA1.hexdigest(Regexp.last_match[2] + Regexp.last_match[3])}#{close_pattern}"
      macro = Regexp.last_match[2]
      argstr = Regexp.last_match[3]
      args = []
      opts = {}
      
      argstr.scan(/,?\s*(#{arg})\s*/) do |arguments|
      	# Stabstabstab
      	argument = arguments.first
      	
        if argument =~ /^([a-z0-9_]+)="(.*?)"/
      		opts[Regexp.last_match[1]] = Regexp.last_match[2]
			  elsif argument =~ /^"(.*)"$/
      		args << Regexp.last_match[1]
			  else
				  args << argument
        end
      end
		  
		  args << opts unless opts.empty?
      
      @map[id] = { :macro => macro, :args => args }
      id
    end
  end

  def process(data)
    @map.each do |id, spec|
      macro = spec[:macro]
      args  = spec[:args]

      data.gsub!(id) do
        begin
          Gollum::Macro.instance(macro, @markup.wiki, @markup.page).render(*args)
        rescue StandardError => e
          icon = Octicons::Octicon.new('zap', {width: 24, height: 24})
          icon.options[:class] << ' mr-2'
          "<div class='flash flash-error'>#{icon.to_svg}Macro Error for #{macro}: #{e.message}</div>"
        end
      end
    end

    data
  end
end
