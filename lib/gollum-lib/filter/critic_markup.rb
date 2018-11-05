# ~*~ encoding: utf-8 ~*~

# CriticMarkup
#
# Render CriticMarkup

class Gollum::Filter::CriticMarkup < Gollum::Filter

  # Patterns inspired by https://github.com/DivineDominion/criticmarkup.tmbundle/blob/master/Syntaxes/criticmarkup.tmLanguage
  # All patterns use multiline matching (m flag)
  # Logic inspired by https://github.com/CriticMarkup/CriticMarkup-toolkit/blob/master/CLI/criticParser_CLI.py
  
  ADDITION_PATTERN      = %r|{\+\+(?<content>.*?)\+\+[ \t]*(\[(.*?)\])?[ \t]*\}|m
  DELETION_PATTERN      = %r|{--(?<content>.*?)--[ \t]*(\[(.*?)\])?[ \t]*\}|m
  SUBSTITUTION_PATTERN  = %r|{~~(?<oldcontent>.*?)~>(?<newcontent>.*?)~~}|m
  HIGHLIGHT_PATTERN     = %r|{\=\=(?<content>.*?)[ \t]*(\[(.*?)\])?[ \t]*\=\=\}{>>(?<comment>.*?)<<}|m
  COMMENT_PATTERN       = %r|{>>(?<content>.*?)<<}|m

  PROCESS_PATTERN       = /(?<placeholder>=CRITIC\h{40})/


  def extract(data)
    data.gsub! ADDITION_PATTERN do
      content = $~[:content]
      placeholder = "=CRITIC" + Digest::SHA1.hexdigest("#{content}#{@map.size}")
    	# Is there a new paragraph followed by new text
      if content.start_with?("\n\n") && content != "\n\n"
        html = "\n\n<ins class='critic break'>&nbsp;</ins>\n\n<ins>#{content.gsub('\n', ' ')}</ins>"
    	# Is the addition just a single new paragraph
      elsif content == "\n\n"
        html = "\n\n<ins class='critic break'>&nbsp;</ins>\n\n"
    	# Is it added text followed by a new paragraph?
      elsif content.end_with?("\n\n") && content != "\n\n"
  	    html = "<ins>#{content.gsub('\n', ' ')}</ins>\n\n<ins class='critic break'>&nbsp;</ins>\n\n"
      else
        html = "<ins>#{content.gsub('\n', ' ')}</ins>"
      end
      @map[placeholder] = html
      placeholder
    end
    
    data.gsub! DELETION_PATTERN do
      content = $~[:content]
      placeholder = "=CRITIC" + Digest::SHA1.hexdigest("#{content}#{@map.size}")
      if content == "\n\n"
        html = "<del>&nbsp;</del>"
      else
        html = "<del>#{content.gsub('\n\n', ' ')}</del>"
      end
      @map[placeholder] = html
      placeholder
    end   
    
    data.gsub! SUBSTITUTION_PATTERN do
      oldcontent = $~[:oldcontent]
      newcontent = $~[:newcontent]
      placeholder = "=CRITIC" + Digest::SHA1.hexdigest("#{oldcontent}#{newcontent}#{@map.size}")
      html = "<del>#{oldcontent}</del><ins>#{newcontent}</ins>"
      @map[placeholder] = html
      placeholder
    end

    data.gsub! HIGHLIGHT_PATTERN do
      content = $~[:content]
      comment = $~[:comment]
      placeholder = "=CRITIC" + Digest::SHA1.hexdigest("#{content}#{@map.size}")
      html = "<mark>#{content}</mark><span class='critic comment'>#{comment}</span>"
      @map[placeholder] = html
      placeholder
    end
    
    data.gsub! COMMENT_PATTERN do
      content = $~[:content]
      placeholder = "=CRITIC" + Digest::SHA1.hexdigest("#{content}#{@map.size}")
      html = "<span class='critic comment'>#{content}</span>"
      @map[placeholder] = html
      placeholder
    end
    
    data
  end



  def process(data)
    data.gsub! PROCESS_PATTERN do 
      @map[$~[:placeholder]]
    end
    data
  end


end
