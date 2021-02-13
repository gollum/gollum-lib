# ~*~ encoding: utf-8 ~*~
# Code
#
# Render a block of code using the Rouge syntax-highlighter.

R = :nil
require 'rinruby'
RInterface = RinRuby.new

class Gollum::Filter::Code < Gollum::Filter
  def extract(data)
    case @markup.format
    when :asciidoc
      data.gsub!(/^(\[source,([^\r\n]*)\]\n)?----\n(.+?)\n----$/m) do
        cache_codeblock(Regexp.last_match[2], Regexp.last_match[3])
      end
    when :org
      org_headers = %r{([ \t]*#\+HEADER[S]?:[^\r\n]*\n)*}
      org_name = %r{([ \t]*#\+NAME:[^\r\n]*\n)?}
      org_lang = %r{[ ]*([^\n \r]*)[ ]*[^\r\n]*}
      org_begin = %r{([ \t]*)#\+BEGIN_SRC#{org_lang}\r?\n}
      org_end = %r{\r?\n[ \t]*#\+END_SRC[ \t\r]*}
      data.gsub!(/^#{org_headers}#{org_name}#{org_begin}(.+?)#{org_end}$/mi) do
        "#{Regexp.last_match[3]}#{cache_codeblock(Regexp.last_match[4], Regexp.last_match[5])}"
      end
    when :markdown
      data.gsub!(/^([ ]{0,3})(~~~+) ?([^\r\n]+)?\r?\n(.+?)\r?\n[ ]{0,3}(~~~+)[ \t\r]*$/m) do
        m_indent = Regexp.last_match[1]
        m_start  = Regexp.last_match[2] # ~~~
        m_lang   = Regexp.last_match[3]
        m_code   = Regexp.last_match[4]
        m_end    = Regexp.last_match[5] # ~~~
        # The closing code fence must be at least as long as the opening fence
        next '' if m_end.length < m_start.length
        lang = m_lang ? m_lang.strip.split.first : nil
        "#{m_indent}#{cache_codeblock(lang, m_code, m_indent)}"
      end  
    end
    
    data.gsub!(/^([ ]{0,3})``` ?([^\r\n]+)?\r?\n(.+?)\r?\n[ ]{0,3}```[ \t]*\r?$/m) do
      m_indent = Regexp.last_match[1]
      m_extra   = Regexp.last_match[2]
      m_code   = Regexp.last_match[3]
      if m_extra =~ /^\{(\s+)?r(\s.*)?\}/
        replacement = cache_rblock(m_extra.to_s.strip, m_code, m_indent)
      else
        replacement = cache_codeblock(m_extra.to_s.strip, m_code, m_indent)
      end
      "#{Regexp.last_match[1]}#{replacement}" # print the SHA1 ID with the proper indentation
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

    @map.each do |_id, spec|
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
        # Set the default lexer to 'text' to prevent #153 and #154
        lang = lang || 'text'
        lexer = Pygments::Lexer[(lang)] || Pygments::Lexer['text']

        # must set startinline to true for php to be highlighted without <?
        hl_code = lexer.highlight(code, :options => { :encoding => encoding.to_s, :startinline => true })
      else # Rouge
        begin
          # if `lang` was not defined then assume plaintext
          lexer = Rouge::Lexer.find_fancy(lang || 'plaintext')
          formatter = Rouge::Formatters::HTML.new
          wrap_template = '<pre class="highlight"><code>%s</code></pre>'

          # if `lang` is defined but cannot be found then wrap it with an error
          if lexer.nil?
            lexer = Rouge::Lexers::PlainText
            wrap_template = '<pre class="highlight"><span class="err">%s</span></pre>'
          end

          formatted = formatter.format(lexer.lex(code))

          hl_code = Kernel.sprintf(wrap_template, formatted)
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
      data.gsub!(/(<p>#{id}<\/p>|#{id})/) { body }
    end

    render_r(data)
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
      code.gsub!(regex) { '' }
    end
  end
  
  def generate_placeholder_id(extra, code)
    id = "#{open_pattern}#{Digest::SHA1.hexdigest("#{extra}.#{code}")}#{close_pattern}"
  end
  
  def cache_rblock(extra, code, indent = '')
    id = generate_placeholder_id(extra, code)
    @map[id] = {:output => "#{indent}```#{extra}\n#{code}\n```"}
    id
  end

  def cache_codeblock(language, code, indent = '')
    language = language.to_s.empty? ? nil : language
    id = generate_placeholder_id(language, code)
    cached = @markup.check_cache(:code, id)
    @map[id] = cached ?
      { :output => cached } :
      { :lang => language, :code => code, :indent => indent }
    id
  end
  
  def render_r(content)
    RInterface.eval 'require(knitr)'
    RInterface.assign "content", content
    RInterface.eval "knitr::render_markdown(strict = TRUE)"
    RInterface.pull "(knitr::knit2html(text = content, fragment.only = TRUE))"
  end
end
