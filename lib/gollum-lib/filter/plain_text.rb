# ~*~ encoding: utf-8 ~*~

# Plain Text
#
# Render plain text documents in a <pre> block without any special markup.

class Gollum::Filter::PlainText < Gollum::Filter

  def extract(data)
    @markup.format == :txt ? "<pre>#{CGI.escapeHTML(data)}</pre>" : data
  end

  def process(data); data ; end

end
