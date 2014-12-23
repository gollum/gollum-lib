# ~*~ encoding: utf-8 ~*~

# Code
#
# Render a block of code using the Rouge syntax-highlighter.
class Gollum::Filter::Code < Gollum::Filter
  def extract(data)
    return data if @markup.format == :txt
    data.gsub!(/^([ \t]*)(~~~+) ?([^\r\n]+)?\r?\n(.+?)\r?\n\1(~~~+)[ \t\r]*$/m) do
      m_indent = $1
      m_start  = $2 # ~~~
      m_lang   = $3
      m_code   = $4
      m_end    = $5 # ~~~

      # start and finish tilde fence must be the same length
      next '' if m_start.length != m_end.length

      lang   = m_lang ? m_lang.strip : nil
      id     = Digest::SHA1.hexdigest("#{lang}.#{m_code}")
      cached = @markup.check_cache(:code, id)

      # extract lang from { .ruby } or { #stuff .ruby .indent }
      # see http://johnmacfarlane.net/pandoc/README.html#delimited-code-blocks

      if lang
        lang = lang.match(/\.([^}\s]+)/)
        lang = lang[1] unless lang.nil?
      end

      @map[id] = cached ?
          { :output => cached } :
          { :lang => lang, :code => m_code, :indent => m_indent }

      "#{m_indent}#{id}" # print the SHA1 ID with the proper indentation
    end

    data.gsub!(/^([ \t]*)``` ?([^\r\n]+)?\r?\n(.+?)\r?\n\1```[ \t]*\r?$/m) do
      lang     = $2 ? $2.strip : nil
      id       = Digest::SHA1.hexdigest("#{lang}.#{$3}")
      cached   = @markup.check_cache(:code, id)
      @map[id] = cached ?
          { :output => cached } :
          { :lang => lang, :code => $3, :indent => $1 }
      "#{$1}#{id}" # print the SHA1 ID with the proper indentation
    end

    if @markup.format == :asciidoc then
      data.gsub!(/^(\[source,(.*)\]\n)?----\n(.*)\n----$/m) do
        lang     = $2
        id       = Digest::SHA1.hexdigest("#{lang}.#{$3}")
        cached   = @markup.check_cache(:code, id)
        @map[id] = cached ?
            { :output => cached } :
            { :lang => lang, :code => $3, :indent => "" }
        id
      end
    end

    data
  end

  # Process all code from the codemap and replace the placeholders with the
  # final HTML.
  #
  # data     - The String data (with placeholders).
  # encoding - Encoding Constant or String.
  #
  # Returns the marked up String data.
  def process(data)
    return data if data.nil? || data.size.zero? || @map.size.zero?

    blocks = []

    @map.each do |id, spec|
      next if spec[:output] # cached

      code = spec[:code]

      remove_leading_space(code, /^#{spec[:indent]}/m)
      remove_leading_space(code, /^(  |\t)/m)

      blocks << [spec[:lang], code]
    end

    highlighted = []
    blocks.each do |lang, code|
      encoding = @markup.encoding || 'utf-8'

      if defined? Pygments
        # treat unknown and bash as standard pre tags
        if !lang || lang.downcase == 'bash'
          hl_code = "<pre>#{code}</pre>"
        else
          # must set startinline to true for php to be highlighted without <?
          hl_code = Pygments.highlight(code, :lexer => lang, :options => { :encoding => encoding.to_s, :startinline => true })
        end
      else # Rouge
        begin
          # if `lang` was not defined then assume plaintext
          # if `lang` is defined but cannot be found then wrap it and escape it
          lang ||= 'plaintext'
          if Rouge::Lexer.find(lang).nil?
            lexer     = Rouge::Lexers::PlainText.new
            formatter = Rouge::Formatters::HTML.new(:wrap => false)
            hl_code   = formatter.format(lexer.lex(code))
            hl_code   = "<pre class='highlight'><span class='err'>#{CGI.escapeHTML(hl_code)}</span></pre>"
          else
            hl_code = Rouge.highlight(code, lang, 'html')
          end
        rescue
          hl_code = code
        end
      end

      highlighted << hl_code
    end

    @map.each do |id, spec|
      body = spec[:output] || begin
        if (body = highlighted.shift.to_s).size > 0
          @markup.update_cache(:code, id, body)
          body
        else
          "<pre><code>#{CGI.escapeHTML(spec[:code])}</code></pre>"
        end
      end
      # Removes paragraph tags surrounding <pre> blocks, see issue https://github.com/gollum/gollum-lib/issues/97
      data.gsub!(/(<p>#{id}<\/p>|#{id})/) do
        body
      end
    end

    data
  end

  private
  # Remove the leading space from a code block. Leading space
  # is only removed if every single line in the block has leading
  # whitespace.
  #
  # code      - The code block to remove spaces from
  # regex     - A regex to match whitespace
  def remove_leading_space(code, regex)
    if code.lines.all? { |line| line =~ /\A\r?\n\Z/ || line =~ regex }
      code.gsub!(regex) do
        ''
      end
    end
  end
end
