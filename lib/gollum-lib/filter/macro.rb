# ~*~ encoding: utf-8 ~*~

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
      id = Digest::SHA1.hexdigest(Regexp.last_match[2] + Regexp.last_match[3])
      macro = Regexp.last_match[2]
      argstr = Regexp.last_match[3]
      args = []
      opts = {}
      
      argstr.scan /,?\s*(#{arg})\s*/ do |arg|
      	# Stabstabstab
      	arg = arg.first
      	
      	if arg =~ /^([a-z0-9_]+)="(.*?)"/
      		opts[Regexp.last_match[1]] = Regexp.last_match[2]
			  elsif arg =~ /^"(.*)"$/
      		args << Regexp.last_match[1]
			  else
				  args << arg
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
          "!!!Macro Error: #{e.message}!!!"
        end
      end
    end

    data
  end
end
